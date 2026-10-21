import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/storage/storage_keys.dart';
import '../../ble/cubit/ble_console_cubit.dart';
import '../../ble/data/ble_session_factory.dart';
import '../../mqtt/cubit/mqtt_console_cubit.dart';
import '../../mqtt/data/mqtt_session_factory.dart';
import '../../serial/cubit/serial_console_cubit.dart';
import '../../serial/data/serial_session_factory.dart';
import '../data/home_tab_store.dart';
import '../model/connection_kind.dart';
import '../model/home_tab.dart';
import 'home_tabs_state.dart';

enum HomeTabAddResult { opened, unsupported }

class HomeTabLive {
  const HomeTabLive({required this.open, this.title});

  final bool open;
  final String? title;
}

/// 首页连接页签。同一种协议可以有多个页签；每种协议使用独立会话。
class HomeTabsCubit extends Cubit<HomeTabsState> {
  HomeTabsCubit({
    required SerialSessionFactory sessions,
    required BleSessionFactory ble,
    required MqttSessionFactory mqtt,
    required HomeTabStore tabs,
  }) : _sessions = sessions,
       _ble = ble,
       _mqtt = mqtt,
       _tabs = tabs,
       super(const HomeTabsState.empty());

  final SerialSessionFactory _sessions;
  final BleSessionFactory _ble;
  final MqttSessionFactory _mqtt;
  final HomeTabStore _tabs;
  final Map<String, SerialConsoleCubit> _serials = {};
  final Map<String, BleConsoleCubit> _bles = {};
  final Map<String, MqttConsoleCubit> _mqtts = {};
  final Map<String, Future<void>> _closing = {};
  var _seq = 0;

  SerialConsoleCubit? serialFor(String id) => _serials[id];

  BleConsoleCubit? bleFor(String id) => _bles[id];

  MqttConsoleCubit? mqttFor(String id) => _mqtts[id];

  HomeTabLive liveFor(String id) {
    final serial = _serials[id];
    if (serial != null) {
      return HomeTabLive(open: serial.state.open, title: serial.state.portName);
    }
    final ble = _bles[id];
    if (ble != null) {
      return HomeTabLive(
        open: ble.state.connected,
        title: ble.state.deviceName,
      );
    }
    final mqtt = _mqtts[id];
    if (mqtt != null) {
      return HomeTabLive(open: mqtt.state.connected, title: mqtt.state.endpoint);
    }
    return const HomeTabLive(open: false);
  }

  Future<void> start() async {
    final saved = _tabs.read();
    if (saved == null || saved.tabs.isEmpty) {
      await _open(
        id: _newId(),
        kind: ConnectionKind.serial,
        storageKey: StorageKeys.serialWorkspace,
        activate: true,
      );
      return;
    }
    for (final tab in saved.tabs) {
      await _open(
        id: tab.id,
        kind: tab.kind,
        storageKey: tab.storageKey,
        label: tab.label,
        activate: false,
      );
    }
    final active = saved.activeId;
    final hasActive = state.tabs.any((tab) => tab.id == active);
    emit(state.copyWith(activeId: hasActive ? active : state.tabs.first.id));
    await _persist();
  }

  Future<HomeTabAddResult> add(ConnectionKind kind) async {
    final id = _newId();
    await _open(
      id: id,
      kind: kind,
      storageKey: _storageKey(kind, id),
      activate: true,
    );
    return HomeTabAddResult.opened;
  }

  /// 去掉首尾空白后仍有内容则作为页签名；否则清除自定义名称。
  Future<void> rename(String id, String name) async {
    if (!state.tabs.any((tab) => tab.id == id)) return;
    final label = name.trim();
    emit(
      state.copyWith(
        tabs: [
          for (final tab in state.tabs)
            if (tab.id == id)
              tab.withLabel(label.isEmpty ? null : label)
            else
              tab,
        ],
      ),
    );
    await _persist();
  }

  void select(String id) {
    if (!state.tabs.any((tab) => tab.id == id) || state.activeId == id) return;
    emit(state.copyWith(activeId: id));
    unawaited(_persist());
  }

  /// 先从界面摘掉页签，再在下一轮事件里关闭会话并保存工作区。
  Future<void> closeTab(String id) {
    final serial = _serials.remove(id);
    final ble = _bles.remove(id);
    final mqtt = _mqtts.remove(id);
    final tabs = state.tabs.where((tab) => tab.id != id).toList();
    final active = state.activeId == id
        ? (tabs.isEmpty ? null : tabs.last.id)
        : state.activeId;
    emit(state.copyWith(tabs: tabs, activeId: active));
    unawaited(_persist());
    if (serial == null && ble == null && mqtt == null) {
      return Future<void>.value();
    }
    final done = Future<void>.delayed(Duration.zero, () async {
      if (serial != null && !serial.isClosed) await serial.close();
      if (ble != null && !ble.isClosed) await ble.close();
      if (mqtt != null && !mqtt.isClosed) await mqtt.close();
      _closing.remove(id);
    });
    _closing[id] = done;
    return done;
  }

  @override
  Future<void> close() async {
    final pending = [..._closing.values];
    final serials = [..._serials.values];
    final bles = [..._bles.values];
    final mqtts = [..._mqtts.values];
    _serials.clear();
    _bles.clear();
    _mqtts.clear();
    await Future.wait(pending);
    for (final console in serials) {
      if (!console.isClosed) await console.close();
    }
    for (final console in bles) {
      if (!console.isClosed) await console.close();
    }
    for (final console in mqtts) {
      if (!console.isClosed) await console.close();
    }
    return super.close();
  }

  Future<void> _open({
    required String id,
    required ConnectionKind kind,
    required String storageKey,
    String? label,
    required bool activate,
  }) async {
    if (_serials.containsKey(id) ||
        _bles.containsKey(id) ||
        _mqtts.containsKey(id)) {
      return;
    }
    switch (kind) {
      case ConnectionKind.serial:
        _serials[id] = SerialConsoleCubit(repository: _sessions.open(storageKey));
      case ConnectionKind.ble:
        _bles[id] = BleConsoleCubit(repository: _ble.open(storageKey));
      case ConnectionKind.mqtt:
        _mqtts[id] = MqttConsoleCubit(repository: _mqtt.open(storageKey));
    }
    final tab = HomeTab(
      id: id,
      kind: kind,
      storageKey: storageKey,
      label: label,
    );
    emit(
      state.copyWith(
        tabs: [...state.tabs, tab],
        activeId: activate ? id : state.activeId ?? id,
      ),
    );
    await _serials[id]?.start();
    await _bles[id]?.start();
    await _mqtts[id]?.start();
    await _persist();
  }

  String _storageKey(ConnectionKind kind, String id) {
    final prefix = switch (kind) {
      ConnectionKind.serial => StorageKeys.serialWorkspace,
      ConnectionKind.ble => StorageKeys.bleWorkspace,
      ConnectionKind.mqtt => StorageKeys.mqttWorkspace,
    };
    final inUse = state.tabs.any((tab) => tab.storageKey == prefix);
    return inUse ? '${prefix}_$id' : prefix;
  }

  Future<void> _persist() async {
    try {
      await _tabs.write(
        HomeTabsSnapshot(tabs: state.tabs, activeId: state.activeId),
      );
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '保存首页页签失败',
        category: LogCategory.database,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _newId() => 'tab-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
}
