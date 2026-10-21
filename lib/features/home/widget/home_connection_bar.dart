import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../ble/cubit/ble_console_cubit.dart';
import '../../ble/cubit/ble_console_state.dart';
import '../../mqtt/cubit/mqtt_console_cubit.dart';
import '../../mqtt/cubit/mqtt_console_state.dart';
import '../../serial/cubit/serial_console_cubit.dart';
import '../../serial/cubit/serial_console_state.dart';
import '../../serial/serial_metrics.dart';
import '../cubit/home_tabs_cubit.dart';
import '../model/connection_kind.dart';
import '../model/home_tab.dart';
import 'home_tab_rename.dart';

class HomeConnectionBar extends StatelessWidget {
  const HomeConnectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final state = context.watch<HomeTabsCubit>().state;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: SizedBox(
        height: SerialMetrics.logHead,
        child: Row(
          children: [
            Expanded(
              child: _TabStrip(tabs: state.tabs, activeId: state.activeId),
            ),
            const _AddConnectionButton(),
          ],
        ),
      ),
    );
  }
}

/// 页签超出后横向滑动。纵向滚轮在条上改为横向，当前页被挡住时滚进视野。
class _TabStrip extends StatefulWidget {
  const _TabStrip({required this.tabs, required this.activeId});

  final List<HomeTab> tabs;
  final String? activeId;

  @override
  State<_TabStrip> createState() => _TabStripState();
}

class _TabStripState extends State<_TabStrip> {
  static const _revealDuration = Duration(milliseconds: 150);

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(covariant _TabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeId != widget.activeId ||
        oldWidget.tabs.length != widget.tabs.length) {
      _scheduleReveal();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _revealActive();
    });
  }

  /// builder 不构建屏幕外的子节点，按固定宽度算位置，不用 ensureVisible。
  void _revealActive() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final viewport = position.viewportDimension;
    if (viewport <= 0) return;
    final index = widget.tabs.indexWhere((tab) => tab.id == widget.activeId);
    if (index < 0) return;
    const width = SerialMetrics.connectionTab;
    final start = index * width;
    final end = start + width;
    final visibleStart = position.pixels;
    final visibleEnd = visibleStart + viewport;
    final double? target;
    if (start < visibleStart) {
      target = start;
    } else if (end > visibleEnd) {
      target = end - viewport;
    } else {
      target = null;
    }
    if (target == null) return;
    final next = target.clamp(0.0, position.maxScrollExtent);
    if ((next - position.pixels).abs() < 0.5) return;
    _controller.animateTo(
      next,
      duration: _revealDuration,
      curve: Curves.easeOut,
    );
  }

  /// 纵向滚轮和横向触控板取幅度较大的一轴，并吃掉事件，避免外层跟着滚。
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final scroll = event.scrollDelta;
    final delta = scroll.dy.abs() >= scroll.dx.abs() ? scroll.dy : scroll.dx;
    if (delta == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      if (!_controller.hasClients) return;
      _controller.position.pointerScroll(delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _TabStripScrollBehavior(),
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: ListView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          itemExtent: SerialMetrics.connectionTab,
          itemCount: widget.tabs.length,
          itemBuilder: (context, index) {
            final tab = widget.tabs[index];
            return _ConnectionTab(
              tab: tab,
              selected: tab.id == widget.activeId,
            );
          },
        ),
      ),
    );
  }
}

class _TabStripScrollBehavior extends MaterialScrollBehavior {
  const _TabStripScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class _ConnectionTab extends StatelessWidget {
  const _ConnectionTab({required this.tab, required this.selected});

  final HomeTab tab;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cubit = context.read<HomeTabsCubit>();
    final color = _kindColor(context, tab.kind);
    return Material(
      color: selected ? palette.field : palette.panel,
      child: InkWell(
        onTap: () => cubit.select(tab.id),
        onSecondaryTapUp: (details) => _openMenu(context, details),
        child: Container(
          width: SerialMetrics.connectionTab,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: palette.line),
              bottom: BorderSide(
                color: selected ? palette.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: _liveBody(context, cubit, color),
        ),
      ),
    );
  }

  Widget _liveBody(BuildContext context, HomeTabsCubit cubit, Color color) {
    final serial = cubit.serialFor(tab.id);
    if (serial != null) {
      return BlocBuilder<SerialConsoleCubit, SerialConsoleState>(
        bloc: serial,
        buildWhen: (a, b) => a.portName != b.portName || a.open != b.open,
        builder: (context, state) {
          return _TabBody(
            tab: tab,
            open: state.open,
            title: _tabTitle(context, tab, state.portName),
            color: color,
            onClose: () => cubit.closeTab(tab.id),
          );
        },
      );
    }
    final ble = cubit.bleFor(tab.id);
    if (ble != null) {
      return BlocBuilder<BleConsoleCubit, BleConsoleState>(
        bloc: ble,
        buildWhen: (a, b) =>
            a.deviceName != b.deviceName || a.connected != b.connected,
        builder: (context, state) {
          return _TabBody(
            tab: tab,
            open: state.connected,
            title: _tabTitle(context, tab, state.deviceName),
            color: color,
            onClose: () => cubit.closeTab(tab.id),
          );
        },
      );
    }
    final mqtt = cubit.mqttFor(tab.id);
    if (mqtt != null) {
      return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
        bloc: mqtt,
        buildWhen: (a, b) =>
            a.host != b.host || a.port != b.port || a.connected != b.connected,
        builder: (context, state) {
          return _TabBody(
            tab: tab,
            open: state.connected,
            title: _tabTitle(context, tab, state.endpoint),
            color: color,
            onClose: () => cubit.closeTab(tab.id),
          );
        },
      );
    }
    return _TabBody(
      tab: tab,
      open: false,
      title: _tabTitle(context, tab, null),
      color: color,
      onClose: () => cubit.closeTab(tab.id),
    );
  }

  void _openMenu(BuildContext context, TapUpDetails details) {
    final cubit = context.read<HomeTabsCubit>();
    final live = cubit.liveFor(tab.id);
    final title = _tabTitle(context, tab, live.title);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(details.globalPosition.dx, details.globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );
    final label = Translations.of(context).home.rename;
    showMenu<void>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<void>(
          onTap: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              showHomeTabRename(
                context,
                cubit: cubit,
                id: tab.id,
                initial: title,
              );
            });
          },
          child: Text(label),
        ),
      ],
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.tab,
    required this.open,
    required this.title,
    required this.color,
    required this.onClose,
  });

  final HomeTab tab;
  final bool open;
  final String title;
  final Color color;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final t = Translations.of(context);
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: open ? color : palette.lampIdle,
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: SerialMetrics.pin,
            height: SerialMetrics.pin,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              _kindBadge(t, tab.kind),
              style: AppTextStyles.mono(
                Theme.of(context).colorScheme,
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: AppTextStyles.caption(
              Theme.of(context).colorScheme,
            ).copyWith(color: palette.text),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        InkWell(
          onTap: onClose,
          child: Icon(Icons.close, size: AppSpacing.lg, color: palette.muted),
        ),
      ],
    );
  }
}

class _AddConnectionButton extends StatelessWidget {
  const _AddConnectionButton();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cubit = context.read<HomeTabsCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: MenuAnchor(
        menuChildren: [
          for (final kind in ConnectionKind.values)
            MenuItemButton(
              onPressed: () => cubit.add(kind),
              child: Text(_kindName(context, kind)),
            ),
        ],
        builder: (context, controller, child) {
          return TextButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: Text(
              t.home.addConnection,
              style: AppTextStyles.caption(
                Theme.of(context).colorScheme,
              ).copyWith(color: palette.text),
            ),
          );
        },
      ),
    );
  }
}

String _tabTitle(BuildContext context, HomeTab tab, String? portName) {
  final label = tab.label?.trim() ?? '';
  if (label.isNotEmpty) return label;
  final port = portName?.trim() ?? '';
  if (port.isNotEmpty) return port;
  return _kindName(context, tab.kind);
}

String _kindName(BuildContext context, ConnectionKind kind) {
  final t = Translations.of(context);
  return switch (kind) {
    ConnectionKind.serial => t.home.kindSerial,
    ConnectionKind.ble => t.home.kindBle,
    ConnectionKind.mqtt => t.home.kindMqtt,
  };
}

String _kindBadge(Translations t, ConnectionKind kind) {
  return switch (kind) {
    ConnectionKind.serial => t.home.badgeSerial,
    ConnectionKind.ble => t.home.badgeBle,
    ConnectionKind.mqtt => t.home.badgeMqtt,
  };
}

Color _kindColor(BuildContext context, ConnectionKind kind) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (kind) {
    ConnectionKind.serial =>
      dark ? AppColors.protocolSerialDark : AppColors.protocolSerial,
    ConnectionKind.ble =>
      dark ? AppColors.protocolBleDark : AppColors.protocolBle,
    ConnectionKind.mqtt =>
      dark ? AppColors.protocolMqttDark : AppColors.protocolMqtt,
  };
}
