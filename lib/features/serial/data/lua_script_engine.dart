import 'dart:convert';
import 'dart:typed_data';

import 'package:lua_dardo_plus/lua.dart';
// ignore: implementation_imports
import 'package:lua_dardo_plus/src/state/lua_state_impl.dart';

import '../model/serial_models.dart';

class ScriptOutcome {
  const ScriptOutcome({
    this.logs = const [],
    this.error,
    this.bytes,
    this.tooLong = false,
  });

  final List<String> logs;
  final String? error;

  /// 超过指令上限被中止（多半是死循环）。
  final bool tooLong;

  /// 仅 before_send：处理后的帧；null 表示拦截（含出错）。
  final Uint8List? bytes;
}

/// 每个脚本独立一个 Lua 虚拟机；代码变化时重建，保证全局状态与代码一致。
class LuaScriptEngine {
  LuaScriptEngine({this.instructionBudget = 2000000});

  /// 单次执行允许的最大指令数，超出视为死循环并中止。
  final int instructionBudget;

  final Map<String, _Vm> _vms = {};

  /// 代码中定义了哪些钩子；编译失败时返回错误。
  ({Set<ScriptHook> hooks, String? error}) inspect(String id, String code) {
    final vm = _vm(id, code);
    return (hooks: vm.hooks, error: vm.error);
  }

  ScriptOutcome receive(String id, String code, Uint8List frame) {
    final vm = _vm(id, code);
    if (vm.error != null) return ScriptOutcome(error: vm.error);
    if (!vm.hooks.contains(ScriptHook.onReceive)) return const ScriptOutcome();
    return vm.call('on_receive', frame, wantBytes: false);
  }

  ScriptOutcome beforeSend(String id, String code, Uint8List frame) {
    final vm = _vm(id, code);
    if (vm.error != null) return ScriptOutcome(error: vm.error);
    if (!vm.hooks.contains(ScriptHook.beforeSend)) {
      return ScriptOutcome(bytes: frame);
    }
    return vm.call('before_send', frame, wantBytes: true);
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
    for (final hook in ScriptHook.values) {
      _state.getGlobal(_name(hook));
      if (_state.isFunction(-1)) hooks.add(hook);
      _state.pop(1);
    }
  }

  final String code;
  final int budget;
  final _BudgetState _state = _BudgetState();
  final List<String> _logs = [];
  final Set<ScriptHook> hooks = {};
  String? error;
  bool _exceeded = false;

  static String _name(ScriptHook hook) => switch (hook) {
    ScriptHook.onReceive => 'on_receive',
    ScriptHook.beforeSend => 'before_send',
  };

  ScriptOutcome call(String name, Uint8List frame, {required bool wantBytes}) {
    _logs.clear();
    _exceeded = false;
    final top = _state.getTop();
    _state.getGlobal('__hook');
    _state.pushString(name);
    _state.createTable(frame.length, 0);
    for (var i = 0; i < frame.length; i++) {
      _state.pushInteger(frame[i]);
      _state.rawSetI(-2, i + 1);
    }
    final err = _run(() => _state.pCall(2, 1, 0));
    final logs = List<String>.of(_logs);
    if (err != null) {
      _state.setTop(top);
      return ScriptOutcome(logs: logs, error: err, tooLong: _exceeded);
    }
    Uint8List? bytes;
    String? badReturn;
    if (wantBytes) {
      if (_state.isTable(-1)) {
        final n = _state.rawLen(-1);
        final out = Uint8List(n);
        for (var i = 0; i < n; i++) {
          _state.rawGetI(-1, i + 1);
          out[i] = (_state.toIntegerX(-1) ?? 0) & 0xFF;
          _state.pop(1);
        }
        bytes = out;
      } else if (_state.isString(-1) && !_state.isNumber(-1)) {
        bytes = Uint8List.fromList(latin1.encode(_state.toStr(-1) ?? ''));
      } else if (!_state.isNil(-1)) {
        badReturn = 'before_send must return a frame or nil';
      }
    }
    _state.setTop(top);
    return ScriptOutcome(logs: logs, error: badReturn, bytes: bytes);
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

/// lua_dardo_plus 的词法分析器无法识别 0x 十六进制整数，编译前改写为十进制；
/// 跳过字符串与注释，不增删换行以保持行号。
String rewriteHexLiterals(String src) {
  final out = StringBuffer();
  var i = 0;
  final n = src.length;
  bool isWord(int c) =>
      (c >= 0x30 && c <= 0x39) ||
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      c == 0x5F;
  // 长括号 [[ ]] / [==[ ]==]，返回结束位置；不是长括号返回 -1。
  int longBracket(int start) {
    if (src.codeUnitAt(start) != 0x5B) return -1;
    var j = start + 1;
    while (j < n && src.codeUnitAt(j) == 0x3D) {
      j++;
    }
    if (j >= n || src.codeUnitAt(j) != 0x5B) return -1;
    final close = ']${'=' * (j - start - 1)}]';
    final end = src.indexOf(close, j + 1);
    return end < 0 ? n : end + close.length;
  }

  while (i < n) {
    final c = src.codeUnitAt(i);
    if (c == 0x2D && i + 1 < n && src.codeUnitAt(i + 1) == 0x2D) {
      final long = i + 2 < n ? longBracket(i + 2) : -1;
      var end = long;
      if (end < 0) {
        end = src.indexOf('\n', i);
        if (end < 0) end = n;
      }
      out.write(src.substring(i, end));
      i = end;
      continue;
    }
    if (c == 0x5B) {
      final end = longBracket(i);
      if (end > 0) {
        out.write(src.substring(i, end));
        i = end;
        continue;
      }
    }
    if (c == 0x22 || c == 0x27) {
      var j = i + 1;
      while (j < n) {
        final d = src.codeUnitAt(j);
        if (d == 0x5C) {
          j += 2;
          continue;
        }
        if (d == c || d == 0x0A) break;
        j++;
      }
      final end = j < n ? j + 1 : n;
      out.write(src.substring(i, end));
      i = end;
      continue;
    }
    if (isWord(c)) {
      var j = i + 1;
      while (j < n && isWord(src.codeUnitAt(j))) {
        j++;
      }
      final word = src.substring(i, j);
      final hex = RegExp(r'^0[xX]([0-9A-Fa-f]+)$').firstMatch(word);
      if (hex != null && (j >= n || src.codeUnitAt(j) != 0x2E)) {
        final value = BigInt.parse(
          hex.group(1)!,
          radix: 16,
        ).toUnsigned(64).toSigned(64);
        out.write(value.isNegative ? '($value)' : '$value');
      } else {
        out.write(word);
      }
      i = j;
      continue;
    }
    out.writeCharCode(c);
    i++;
  }
  return out.toString();
}

/// 移除可能结束进程或改动磁盘的函数。
const _sandbox = '''
os.exit = nil
os.execute = nil
os.remove = nil
os.rename = nil
os.tmpname = nil
''';

/// 帧对象与常用工具函数；字节下标从 1 开始，u16 为大端。
const _prelude = r'''
local Frame = {}
Frame.__index = Frame
local function wrap(t) return setmetatable(t, Frame) end
local function isframe(v) return getmetatable(v) == Frame end

local function push(out, v)
  local tv = type(v)
  if tv == 'table' then
    for i = 1, #v do out[#out + 1] = math.floor(v[i]) & 0xFF end
  elseif tv == 'string' then
    for i = 1, string.len(v) do out[#out + 1] = string.byte(v, i) end
  elseif tv == 'number' then
    out[#out + 1] = math.floor(v) & 0xFF
  else
    error('cannot append ' .. tv)
  end
end

function frame(...)
  local out = wrap({})
  for i = 1, select('#', ...) do push(out, (select(i, ...))) end
  return out
end

function Frame:len() return #self end
function Frame:u8(i) return self[i] or 0 end
function Frame:u16(i) return ((self[i] or 0) << 8) | (self[i + 1] or 0) end
function Frame:u16le(i) return (self[i] or 0) | ((self[i + 1] or 0) << 8) end

function Frame:starts_with(...)
  local want = {...}
  if #want == 1 and type(want[1]) == 'table' then want = want[1] end
  if #want > #self then return false end
  for i = 1, #want do
    if self[i] ~= want[i] then return false end
  end
  return true
end

function Frame:append(...)
  local out = wrap({})
  for i = 1, #self do out[i] = self[i] end
  for i = 1, select('#', ...) do push(out, (select(i, ...))) end
  return out
end

function Frame:sub(i, j)
  local n = #self
  i = i or 1
  j = j or n
  if i < 0 then i = n + i + 1 end
  if j < 0 then j = n + j + 1 end
  local out = wrap({})
  for k = math.max(i, 1), math.min(j, n) do out[#out + 1] = self[k] end
  return out
end

function Frame:hex()
  local parts = {}
  for i = 1, #self do parts[i] = string.format('%02X', self[i]) end
  return table.concat(parts, ' ')
end

function Frame:str()
  local parts = {}
  for i = 1, #self do parts[i] = string.char(self[i]) end
  return table.concat(parts)
end

function sum8(f)
  local s = 0
  for i = 1, #f do s = s + f[i] end
  return s & 0xFF
end

function xor8(f)
  local s = 0
  for i = 1, #f do s = s ~ f[i] end
  return s
end

-- Modbus CRC16，返回低字节、高字节
function crc16(f)
  local crc = 0xFFFF
  for i = 1, #f do
    crc = crc ~ f[i]
    for _ = 1, 8 do
      if crc & 1 == 1 then
        crc = (crc >> 1) ~ 0xA001
      else
        crc = crc >> 1
      end
    end
  end
  return crc & 0xFF, (crc >> 8) & 0xFF
end

function log(...)
  local parts = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    parts[i] = isframe(v) and v:hex() or tostring(v)
  end
  __log(table.concat(parts, ' '))
end
print = log

function __hook(name, t)
  local f = _G[name]
  return f(wrap(t))
end
''';
