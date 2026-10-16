import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/storage/storage_keys.dart';
import '../../serial/cubit/serial_console_cubit.dart';
import '../../serial/data/serial_session_factory.dart';
import '../data/home_tab_store.dart';
import '../model/connection_kind.dart';
import '../model/home_tab.dart';
import 'home_tabs_state.dart';

enum HomeTabAddResult { opened, unsupported }

/// 首页连接页签。同一种协议可以有多个页签；每个串口页签使用独立会话。
class HomeTabsCubit extends Cubit<HomeTabsState> {
  HomeTabsCubit({
    required SerialSessionFactory sessions,
    required HomeTabStore tabs,
  }) : _sessions = sessions,
       _tabs = tabs,
       super(const HomeTabsState.empty());

  final SerialSessionFactory _sessions;
  final HomeTabStore _tabs;
  final Map<String, SerialConsoleCubit> _consoles = {};
  final Map<String, Future<void>> _closing = {};
  var _seq = 0;

  SerialConsoleCubit? consoleFor(String id) => _consoles[id];

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
    if (!kind.implemented) return HomeTabAddResult.unsupported;
    final id = _newId();
    final legacyInUse = state.tabs.any(
      (tab) => tab.storageKey == StorageKeys.serialWorkspace,
    );
    await _open(
      id: id,
      kind: kind,
      storageKey: legacyInUse
          ? '${StorageKeys.serialWorkspace}_$id'
          : StorageKeys.serialWorkspace,
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

  /// 先从界面摘掉页签，再在下一轮事件里关闭串口并保存工作区。
  Future<void> closeTab(String id) {
    final console = _consoles.remove(id);
    final tabs = state.tabs.where((tab) => tab.id != id).toList();
    final active = state.activeId == id
        ? (tabs.isEmpty ? null : tabs.last.id)
        : state.activeId;
    emit(state.copyWith(tabs: tabs, activeId: active));
    unawaited(_persist());
    if (console == null) return Future<void>.value();
    final done = Future<void>.delayed(Duration.zero, () async {
      if (!console.isClosed) await console.close();
      _closing.remove(id);
    });
    _closing[id] = done;
    return done;
  }

  @override
  Future<void> close() async {
    final pending = [..._closing.values];
    final live = [..._consoles.values];
    _consoles.clear();
    await Future.wait(pending);
    for (final console in live) {
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
    if (!kind.implemented || _consoles.containsKey(id)) return;
    final console = SerialConsoleCubit(repository: _sessions.open(storageKey));
    _consoles[id] = console;
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
    await console.start();
    await _persist();
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
