import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../ble/data/ble_session_factory.dart';
import '../../ble/page/ble_console_page.dart';
import '../../license/cubit/license_cubit.dart';
import '../../license/cubit/license_state.dart';
import '../../license/widget/license_banner.dart';
import '../../license/widget/license_support_dialog.dart';
import '../../mcp/cubit/mcp_cubit.dart';
import '../../mqtt/data/mqtt_session_factory.dart';
import '../../mqtt/page/mqtt_console_page.dart';
import '../../serial/data/serial_session_factory.dart';
import '../../serial/page/serial_console_page.dart';
import '../../socket/data/socket_session_factory.dart';
import '../../socket/page/socket_console_page.dart';
import '../../update/widget/update_dialogs.dart';
import '../cubit/home_tabs_cubit.dart';
import '../data/home_mcp_bridge.dart';
import '../data/home_tab_store.dart';
import '../model/connection_kind.dart';
import '../model/home_tab.dart';
import '../widget/home_connection_bar.dart';

/// 首页：连接页签 + 当前页签的调试台。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeTabsCubit(
        sessions: context.read<SerialSessionFactory>(),
        ble: context.read<BleSessionFactory>(),
        mqtt: context.read<MqttSessionFactory>(),
        sockets: context.read<SocketSessionFactory>(),
        tabs: context.read<HomeTabStore>(),
      )..start(),
      child: const UpdateHost(child: _HomeLicenseMcpGate(child: _HomeView())),
    );
  }
}

/// 绑定 MCP 工作台，并按授权状态启停本机监听；试用结束后启动弹一次支持窗。
class _HomeLicenseMcpGate extends StatefulWidget {
  const _HomeLicenseMcpGate({required this.child});

  final Widget child;

  @override
  State<_HomeLicenseMcpGate> createState() => _HomeLicenseMcpGateState();
}

class _HomeLicenseMcpGateState extends State<_HomeLicenseMcpGate> {
  McpCubit? _mcp;
  var _supportPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mcp = context.read<McpCubit>();
      final home = context.read<HomeTabsCubit>();
      _mcp!.bindWorkbench(HomeMcpBridge(home));
      _syncLicense(context.read<LicenseCubit>().state);
    });
  }

  @override
  void dispose() {
    _mcp?.unbindWorkbench();
    super.dispose();
  }

  Future<void> _syncLicense(LicenseState license) async {
    if (!license.ready || !mounted) return;
    final mcp = _mcp ?? context.read<McpCubit>();
    await mcp.setLicenseActive(license.isActivated);
    if (!mounted) return;
    if (license.isActivated) {
      _supportPrompted = true;
    }
    // 试用中不弹；加载失败时 deviceCode 为空也不弹。
    if (!license.inTrial &&
        !license.isActivated &&
        license.deviceCode.isNotEmpty &&
        !_supportPrompted) {
      _supportPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showLicenseSupportDialog(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LicenseCubit, LicenseState>(
      listenWhen: (a, b) =>
          a.ready != b.ready ||
          a.isActivated != b.isActivated ||
          a.inTrial != b.inTrial ||
          a.showUnlicensedBanner != b.showUnlicensedBanner,
      listener: (context, state) {
        _syncLicense(state);
      },
      child: widget.child,
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabsCubit>().state;
    final palette = SerialPalette.of(context);
    if (state.tabs.isEmpty) {
      final t = Translations.of(context);
      return ColoredBox(
        color: palette.win,
        child: Column(
          children: [
            const _ConnectionChrome(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    t.home.emptyConnections,
                    style: AppTextStyles.body(
                      Theme.of(context).colorScheme,
                    ).copyWith(color: palette.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final index = state.tabs.indexWhere((tab) => tab.id == state.activeId);
    return IndexedStack(
      index: index < 0 ? 0 : index,
      sizing: StackFit.expand,
      children: [
        for (final tab in state.tabs)
          _TabPane(
            key: ValueKey(tab.id),
            tab: tab,
            active: tab.id == state.activeId,
          ),
      ],
    );
  }
}

class _TabPane extends StatelessWidget {
  const _TabPane({super.key, required this.tab, required this.active});

  final HomeTab tab;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final home = context.read<HomeTabsCubit>();
    // 每个页签都挂连接栏，避免切换页签时卸掉栏上的交互控件。
    const chrome = _ConnectionChrome();
    switch (tab.kind) {
      case ConnectionKind.serial:
        final console = home.serialFor(tab.id);
        if (console == null) return const SizedBox.shrink();
        return BlocProvider.value(
          value: console,
          child: SerialConsoleView(shortcutsEnabled: active, belowMenu: chrome),
        );
      case ConnectionKind.ble:
        final console = home.bleFor(tab.id);
        if (console == null) return const SizedBox.shrink();
        return BlocProvider.value(
          value: console,
          child: BleConsoleView(shortcutsEnabled: active, belowMenu: chrome),
        );
      case ConnectionKind.mqtt:
        final console = home.mqttFor(tab.id);
        if (console == null) return const SizedBox.shrink();
        return BlocProvider.value(
          value: console,
          child: MqttConsoleView(shortcutsEnabled: active, belowMenu: chrome),
        );
      case ConnectionKind.tcp:
      case ConnectionKind.udp:
        final console = home.socketFor(tab.id);
        if (console == null) return const SizedBox.shrink();
        return BlocProvider.value(
          value: console,
          child: SocketConsoleView(shortcutsEnabled: active, belowMenu: chrome),
        );
    }
  }
}

/// 页签栏 + 未激活提示（提示仅在需要时占位）。
class _ConnectionChrome extends StatelessWidget {
  const _ConnectionChrome();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeConnectionBar(),
        LicenseBanner(),
      ],
    );
  }
}
