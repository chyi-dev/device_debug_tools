import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../home/widget/workbench_menu_bar.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_editors.dart';
import '../cubit/mqtt_console_cubit.dart';
import '../cubit/mqtt_console_state.dart';
import '../model/mqtt_models.dart';
import '../widget/mqtt_compose.dart';
import '../widget/mqtt_l10n.dart';
import '../widget/mqtt_log_view.dart';
import '../widget/mqtt_side_panel.dart';
import '../widget/mqtt_status_bar.dart';
import '../widget/mqtt_tools_panel.dart';

class MqttConsoleView extends StatefulWidget {
  const MqttConsoleView({
    super.key,
    this.belowMenu,
    this.shortcutsEnabled = true,
  });

  final Widget? belowMenu;
  final bool shortcutsEnabled;

  @override
  State<MqttConsoleView> createState() => _MqttConsoleViewState();
}

class _MqttConsoleViewState extends State<MqttConsoleView> {
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  Timer? _toastTimer;
  MqttNotice? _toast;
  var _narrowApplied = false;

  @override
  void initState() {
    super.initState();
    if (widget.shortcutsEnabled) {
      HardwareKeyboard.instance.addHandler(_onKey);
    }
  }

  @override
  void didUpdateWidget(MqttConsoleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shortcutsEnabled == widget.shortcutsEnabled) return;
    if (widget.shortcutsEnabled) {
      HardwareKeyboard.instance.addHandler(_onKey);
    } else {
      HardwareKeyboard.instance.removeHandler(_onKey);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width;
    if (!_narrowApplied && width < SerialMetrics.minWindow) {
      _narrowApplied = true;
      context.read<MqttConsoleCubit>().patch(compact: true);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _toastTimer?.cancel();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    final cubit = context.read<MqttConsoleCubit>();
    final key = event.logicalKey;
    final shortcut =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (shortcut && key == LogicalKeyboardKey.keyS) {
      cubit.saveLog();
      return true;
    }
    if (shortcut && key == LogicalKeyboardKey.keyL) {
      cubit.clearLog();
      return true;
    }
    if (shortcut && key == LogicalKeyboardKey.keyF) {
      _searchFocus.requestFocus();
      return true;
    }
    if (key == LogicalKeyboardKey.f12) {
      showShortcutHelp(context);
      return true;
    }
    final fn = {
      LogicalKeyboardKey.f1: 'F1',
      LogicalKeyboardKey.f2: 'F2',
      LogicalKeyboardKey.f3: 'F3',
      LogicalKeyboardKey.f4: 'F4',
      LogicalKeyboardKey.f5: 'F5',
      LogicalKeyboardKey.f6: 'F6',
      LogicalKeyboardKey.f7: 'F7',
      LogicalKeyboardKey.f8: 'F8',
    };
    final bound = fn[key];
    if (bound != null) {
      cubit.sendQuickByKey(bound);
      return true;
    }
    return false;
  }

  void _showToast(MqttNotice notice) {
    _toastTimer?.cancel();
    setState(() => _toast = notice);
    _toastTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final t = Translations.of(context);
    return Material(
      color: palette.win,
      child: BlocListener<MqttConsoleCubit, MqttConsoleState>(
        listenWhen: (previous, current) =>
            previous.toast?.id != current.toast?.id,
        listener: (context, state) {
          final toast = state.toast;
          if (toast != null) _showToast(toast);
        },
        child: BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
          buildWhen: (a, b) =>
              a.compact != b.compact || a.toolsVisible != b.toolsVisible,
          builder: (context, chrome) {
            final cubit = context.read<MqttConsoleCubit>();
            return Stack(
              children: [
                Column(
                  children: [
                    WorkbenchMenuBar(
                      compact: chrome.compact,
                      toolsOn: chrome.toolsVisible,
                      fileItems: [
                        WorkbenchMenuAction(
                          t.mqtt.saveLog,
                          cubit.saveLog,
                          kbd: t.serial.kbd.ctrlS,
                        ),
                      ],
                      toolItems: [
                        WorkbenchMenuAction(
                          t.serial.tab.quick,
                          () => cubit.patch(toolsVisible: true),
                        ),
                      ],
                      onCompact: () => cubit.patch(compact: !chrome.compact),
                      onTools: () =>
                          cubit.patch(toolsVisible: !chrome.toolsVisible),
                      onKeys: () => showShortcutHelp(context),
                      onAbout: () => showSerialAbout(context),
                      compactLabel: t.mqtt.compact,
                      toolsLabel: t.mqtt.toolsPanel,
                      compactTip: t.mqtt.compactTip,
                      toolsTip: t.mqtt.toolsTip,
                    ),
                    if (widget.belowMenu != null) widget.belowMenu!,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            if (!chrome.compact) ...[
                              const SizedBox(
                                width: SerialMetrics.sidebar,
                                child: MqttSidePanel(),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child:
                                        BlocBuilder<
                                          MqttConsoleCubit,
                                          MqttConsoleState
                                        >(
                                          buildWhen: (a, b) =>
                                              a.lines != b.lines,
                                          builder: (context, state) {
                                            return MqttLogView(
                                              state: state,
                                              search: _query,
                                              searchFocus: _searchFocus,
                                              onSearch: (value) => setState(
                                                () => _query = value,
                                              ),
                                              onClear: cubit.clearLog,
                                            );
                                          },
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  const MqttCompose(),
                                ],
                              ),
                            ),
                            if (chrome.toolsVisible) ...[
                              const SizedBox(width: AppSpacing.sm),
                              const SizedBox(
                                width: SerialMetrics.tools,
                                child: MqttToolsPanel(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const MqttStatusBar(),
                  ],
                ),
                if (_toast != null)
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: SerialMetrics.statusBar + AppSpacing.md,
                    child: Material(
                      color: _toast!.warn ? palette.off : palette.field,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          mqttNoticeText(t, _toast!),
                          style: AppTextStyles.body(Theme.of(context).colorScheme)
                              .copyWith(
                                color: _toast!.warn
                                    ? Colors.white
                                    : palette.text,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
