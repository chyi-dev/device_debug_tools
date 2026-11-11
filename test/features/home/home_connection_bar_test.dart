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
import 'package:device_debug_tools/features/socket/data/socket_session_factory.dart';
import 'package:device_debug_tools/features/socket/model/socket_models.dart';
import 'package:device_debug_tools/features/socket/repository/socket_console_repository.dart';
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

  testWidgets('新增连接弹窗为三列宫格，点串口会新增页签', (tester) async {
    cubit.show(const [], '');

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider<HomeTabsCubit>.value(
            value: cubit,
            child: const Scaffold(body: HomeConnectionBar()),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('＋ 新增'));
    await tester.pumpAndSettle();

    expect(find.text('新增连接'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('串口'), findsOneWidget);
    expect(find.text('蓝牙 BLE'), findsOneWidget);
    expect(find.text('MQTT'), findsOneWidget);
    expect(find.text('TCP'), findsOneWidget);
    expect(find.text('UDP'), findsOneWidget);
    expect(find.byIcon(Icons.usb), findsOneWidget);
    expect(find.byIcon(Icons.bluetooth), findsOneWidget);
    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_ethernet), findsOneWidget);
    expect(find.byIcon(Icons.wifi_tethering), findsOneWidget);

    await tester.tap(find.text('串口'));
    await tester.pumpAndSettle();

    expect(find.text('新增连接'), findsNothing);
    expect(cubit.state.tabs, hasLength(1));
    expect(cubit.state.tabs.single.kind, ConnectionKind.serial);
  });
}

/// 只放页签记录，不打开串口会话，避免防抖计时器卡住组件测试。
class _BareTabs extends HomeTabsCubit {
  _BareTabs()
    : super(
        sessions: _UnusedSessions(),
        ble: _UnusedBle(),
        mqtt: _UnusedMqtt(),
        sockets: _UnusedSockets(),
        tabs: _MemoryTabs(),
      );

  void show(List<HomeTab> tabs, String activeId) {
    emit(HomeTabsState(tabs: tabs, activeId: activeId));
  }

  @override
  Future<HomeTabAddResult> add(ConnectionKind kind) async {
    final id = 'tab-${kind.name}-${state.tabs.length}';
    final next = [
      ...state.tabs,
      HomeTab(
        id: id,
        kind: kind,
        storageKey: '${kind.name}_workspace_${state.tabs.length}',
      ),
    ];
    emit(HomeTabsState(tabs: next, activeId: id));
    return HomeTabAddResult.opened;
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

class _UnusedSockets implements SocketSessionFactory {
  @override
  SocketConsoleRepository open(
    String storageKey, {
    required SocketProtocol protocol,
  }) => throw UnsupportedError(storageKey);
}
