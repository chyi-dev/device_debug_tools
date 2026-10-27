import 'dart:convert';
import 'dart:typed_data';

import 'package:lua_dardo_plus/lua.dart';
// ignore: implementation_imports
import 'package:lua_dardo_plus/src/state/lua_state_impl.dart';

import '../../serial/data/lua_script_engine.dart';
import '../model/mqtt_models.dart';

class MqttScriptOutcome {
  const MqttScriptOutcome({
    this.logs = const [],
    this.error,
    this.tooLong = false,
    this.message,
  });

  final List<String> logs;
  final String? error;
  final bool tooLong;

  /// 仅 before_publish：改写后的消息。null 表示拦截（含出错）。
  final MqttScriptMessage? message;
}

/// 每个脚本独立一个 Lua 虚拟机。消息以表 `{topic, payload, qos, retain}` 传入。
class MqttLuaEngine {
  MqttLuaEngine({this.instructionBudget = 2000000});

  final int instructionBudget;
  final Map<String, _Vm> _vms = {};

  ({Set<MqttScriptHook> hooks, String? error}) inspect(String id, String code) {
    final vm = _vm(id, code);
    return (hooks: vm.hooks, error: vm.error);
  }

  MqttScriptOutcome onMessage(
    String id,
    String code,
    MqttScriptMessage message,
  ) {
    final vm = _vm(id, code);
    if (vm.error != null) return MqttScriptOutcome(error: vm.error);
    if (!vm.hooks.contains(MqttScriptHook.onMessage)) {
      return const MqttScriptOutcome();
    }
    return vm.call('on_message', message, wantMessage: false);
  }

  MqttScriptOutcome beforePublish(
    String id,
    String code,
    MqttScriptMessage message,
  ) {
    final vm = _vm(id, code);
    if (vm.error != null) return MqttScriptOutcome(error: vm.error);
    if (!vm.hooks.contains(MqttScriptHook.beforePublish)) {
      return MqttScriptOutcome(message: message);
    }
    return vm.call('before_publish', message, wantMessage: true);
  }

  void forget(String id) => _vms.remove(id);

  void retain(Iterable<String> ids) {
    final keep = ids.toSet();
    _vms.removeWhere((id, _) => !keep.contains(id));
  }

  void dispose() => _vms.clear();

  _Vm _vm(String id, String code) {
    final cached = _vms[id];
    if (cached != null && cached.code == code) return cached;
    return _vms[id] = _Vm(code, instructionBudget);
  }
}

class _BudgetExceeded implements Exception {
  @override
  String toString() => 'instruction budget exceeded';
}

class _BudgetState extends LuaStateImpl {
  int remaining = 0;

  @override
  int fetch() {
    if (--remaining < 0) throw _BudgetExceeded();
    return super.fetch();
  }
}

class _Vm {
  _Vm(this.code, this.budget) {
    _state.remaining = budget;
    _state.openLibs();
    _state.doString(_sandbox);
    _state.register('__log', (ls) {
      _logs.add(ls.toStr(1) ?? '');
      return 0;
    });
    _load(_prelude, 'prelude');
    _state.pCall(0, 0, 0);
    try {
      _load(code, 'script');
    } catch (e) {
      error = _clean('$e');
      return;
    }
    final run = _run(() => _state.pCall(0, 0, 0));
    if (run != null) {
      error = run;
      return;
    }
    for (final hook in MqttScriptHook.values) {
      _state.getGlobal(_name(hook));
      if (_state.isFunction(-1)) hooks.add(hook);
      _state.pop(1);
    }
  }

  final String code;
  final int budget;
  final _BudgetState _state = _BudgetState();
  final List<String> _logs = [];
  final Set<MqttScriptHook> hooks = {};
  String? error;
  bool _exceeded = false;

  static String _name(MqttScriptHook hook) => switch (hook) {
    MqttScriptHook.onMessage => 'on_message',
    MqttScriptHook.beforePublish => 'before_publish',
  };

  MqttScriptOutcome call(
    String name,
    MqttScriptMessage message, {
    required bool wantMessage,
  }) {
    _logs.clear();
    _exceeded = false;
    final top = _state.getTop();
    _state.getGlobal('__hook');
    _state.pushString(name);
    _pushMessage(message);
    final err = _run(() => _state.pCall(2, 1, 0));
    final logs = List<String>.of(_logs);
    if (err != null) {
      _state.setTop(top);
      return MqttScriptOutcome(logs: logs, error: err, tooLong: _exceeded);
    }
    MqttScriptMessage? next;
    String? badReturn;
    if (wantMessage) {
      if (_state.isNil(-1)) {
        next = null;
      } else if (_state.isTable(-1)) {
        final read = _readMessage(message);
        next = read.message;
        badReturn = read.error;
      } else {
        badReturn = 'before_publish must return a message or nil';
      }
    }
    _state.setTop(top);
    return MqttScriptOutcome(logs: logs, error: badReturn, message: next);
  }

  void _pushMessage(MqttScriptMessage message) {
    _state.createTable(0, 4);
    _put('topic', () => _state.pushString(message.topic));
    _put('payload', () => _state.pushString(message.payload));
    _put('qos', () => _state.pushInteger(message.qos));
    _put('retain', () => _state.pushBoolean(message.retain));
  }

  void _put(String key, void Function() push) {
    _state.pushString(key);
    push();
    _state.setTable(-3);
  }

  ({MqttScriptMessage? message, String? error}) _readMessage(
    MqttScriptMessage original,
  ) {
    final topic = _field('topic');
    if (topic.error != null) return (message: null, error: topic.error);
    final payload = _field('payload');
    if (payload.error != null) return (message: null, error: payload.error);
    _state.getField(-1, 'qos');
    int qos = original.qos;
    if (!_state.isNil(-1)) {
      final value = _state.toIntegerX(-1);
      if (value == null || value < 0 || value > 2) {
        _state.pop(1);
        return (message: null, error: 'qos must be 0, 1, or 2');
      }
      qos = value;
    }
    _state.pop(1);
    _state.getField(-1, 'retain');
    var retain = original.retain;
    if (!_state.isNil(-1)) {
      if (!_state.isBoolean(-1)) {
        _state.pop(1);
        return (message: null, error: 'retain must be a boolean');
      }
      retain = _state.toBoolean(-1);
    }
    _state.pop(1);
    return (
      message: MqttScriptMessage(
        topic: topic.value ?? original.topic,
        payload: payload.value ?? original.payload,
        qos: qos,
        retain: retain,
      ),
      error: null,
    );
  }

  ({String? value, String? error}) _field(String key) {
    _state.getField(-1, key);
    if (_state.isNil(-1)) {
      _state.pop(1);
      return (value: null, error: null);
    }
    if (!_state.isString(-1)) {
      _state.pop(1);
      return (value: null, error: '$key must be a string');
    }
    final value = _state.toStr(-1) ?? '';
    _state.pop(1);
    return (value: value, error: null);
  }

  String? _run(ThreadStatus Function() body) {
    _state.remaining = budget;
    final status = body();
    if (status == ThreadStatus.luaOk) return null;
    _exceeded = _state.remaining < 0;
    return _popError();
  }

  void _load(String src, String name) {
    _state.load(
      Uint8List.fromList(utf8.encode(rewriteHexLiterals(src))),
      name,
      't',
    );
  }

  String _popError() {
    final message = _state.toStr(-1) ?? 'error';
    _state.pop(1);
    return _clean(message);
  }

  String _clean(String message) =>
      message.replaceFirst(RegExp(r'^(Exception:\s*|\[unknown\]\s*)'), '');
}

const _sandbox = '''
os.exit = nil
os.execute = nil
os.remove = nil
os.rename = nil
os.tmpname = nil
''';

const _prelude = r'''
function log(...)
  local parts = {}
  for i = 1, select('#', ...) do
    parts[i] = tostring(select(i, ...))
  end
  __log(table.concat(parts, ' '))
end
print = log

function __hook(name, msg)
  local f = _G[name]
  return f(msg)
end
''';
