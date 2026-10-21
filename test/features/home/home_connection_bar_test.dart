import 'package:device_debug_tools/app/theme/app_theme.dart';
import 'package:device_debug_tools/features/home/cubit/home_tabs_cubit.dart';
import 'package:device_debug_tools/features/home/cubit/home_tabs_state.dart';
import 'package:device_debug_tools/features/home/data/home_tab_store.dart';
import 'package:device_debug_tools/features/home/model/connection_kind.dart';
import 'package:device_debug_tools/features/home/model/home_tab.dart';
import 'package:device_debug_tools/features/home/widget/home_connection_bar.dart';
import 'package:device_debug_tools/features/ble/data/ble_session_factory.dart';
import 'package:device_debug_tools/features/ble/repository/ble_console_repository.dart';
import 'package:device_debug_tools/features/mqtt/data/mqtt_session_factory.dart';
import 'package:device_debug_tools/features/mqtt/repository/mqtt_console_repository.dart';
import 'package:device_debug_tools/features/serial/data/serial_session_factory.dart';
import 'package:device_debug_tools/features/serial/repository/serial_console_repository.dart';
import 'package:device_debug_tools/features/serial/serial_metrics.dart';
import 'package:device_debug_tools/i18n/i18n.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _BareTabs cubit;

  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.zh);
    cubit = _BareTabs();
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets('页签超出后可横向滑动，选中页滚入视野', (tester) async {
    final tabs = [
      for (var i = 0; i < 4; i++)
        HomeTab(
          id: 'tab-$i',
          kind: ConnectionKind.serial,
          storageKey: 'serial_workspace_$i',
        ),
    ];
    cubit.show(tabs, tabs.first.id);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider<HomeTabsCubit>.value(
            value: cubit,
            child: const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 400, child: HomeConnectionBar()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(position.maxScrollExtent, greaterThan(0));
    expect(position.pixels, 0);

    final origin = tester.getTopLeft(find.byType(HomeConnectionBar));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: origin + const Offset(24, 12),
        scrollDelta: const Offset(0, 120),
      ),
    );
    await tester.pump();
    expect(position.pixels, greaterThan(0));

    cubit.select(tabs.last.id);
    await tester.pump();
    // 滚动动画要逐帧推进，单次长时间 pump 不会把它走完。
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    const width = SerialMetrics.connectionTab;
    final end = tabs.length * width;
    expect(
      end,
      lessThanOrEqualTo(position.pixels + position.viewportDimension + 0.5),
    );
    expect(
      (tabs.length - 1) * width,
      greaterThanOrEqualTo(position.pixels - 0.5),
    );
  });
}

/// 只放页签记录，不打开串口会话，避免防抖计时器卡住组件测试。
class _BareTabs extends HomeTabsCubit {
  _BareTabs()
    : super(
        sessions: _UnusedSessions(),
        ble: _UnusedBle(),
        mqtt: _UnusedMqtt(),
        tabs: _MemoryTabs(),
      );

  void show(List<HomeTab> tabs, String activeId) {
    emit(HomeTabsState(tabs: tabs, activeId: activeId));
  }
}

class _MemoryTabs implements HomeTabStore {
  @override
  HomeTabsSnapshot? read() => null;

  @override
  Future<void> write(HomeTabsSnapshot snapshot) async {}
}

class _UnusedSessions implements SerialSessionFactory {
  @override
  SerialConsoleRepository open(String storageKey) =>
      throw UnsupportedError(storageKey);
}

class _UnusedBle implements BleSessionFactory {
  @override
  BleConsoleRepository open(String storageKey) =>
      throw UnsupportedError(storageKey);
}

class _UnusedMqtt implements MqttSessionFactory {
  @override
  MqttConsoleRepository open(String storageKey) =>
      throw UnsupportedError(storageKey);
}
