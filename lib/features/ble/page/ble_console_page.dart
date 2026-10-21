import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../home/widget/workbench_menu_bar.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_editors.dart';
import '../ble_metrics.dart';
import '../cubit/ble_console_cubit.dart';
import '../cubit/ble_console_state.dart';
import '../model/ble_models.dart';
import '../widget/ble_l10n.dart';
import '../widget/ble_log_view.dart';
import '../widget/ble_send_box.dart';
import '../widget/ble_side_panel.dart';
import '../widget/ble_status_bar.dart';
import '../widget/ble_tools_panel.dart';

class BleConsoleView extends StatefulWidget {
  const BleConsoleView({
    super.key,
    this.belowMenu,
    this.shortcutsEnabled = true,
  });

  final Widget? belowMenu;
  final bool shortcutsEnabled;

  @override
  State<BleConsoleView> createState() => _BleConsoleViewState();
}

class _BleConsoleViewState extends State<BleConsoleView> {
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  Timer? _toastTimer;
  BleNotice? _toast;
  var _narrowApplied = false;

  @override
  void initState() {
    super.initState();
    if (widget.shortcutsEnabled) {
      HardwareKeyboard.instance.addHandler(_onKey);
    }
  }

  @override
  void didUpdateWidget(BleConsoleView oldWidget) {
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
      context.read<BleConsoleCubit>().setCompact(true);
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
    final cubit = context.read<BleConsoleCubit>();
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
    if (key == LogicalKeyboardKey.escape) {
      cubit.stopBatch();
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

  void _showToast(BleNotice notice) {
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
      child: BlocListener<BleConsoleCubit, BleConsoleState>(
        listenWhen: (previous, current) =>
            previous.toast?.id != current.toast?.id,
        listener: (context, state) {
          final toast = state.toast;
          if (toast != null) _showToast(toast);
        },
        child: BlocBuilder<BleConsoleCubit, BleConsoleState>(
          buildWhen: (previous, current) =>
              previous.compact != current.compact ||
              previous.toolsVisible != current.toolsVisible,
          builder: (context, chrome) {
            final cubit = context.read<BleConsoleCubit>();
            return Stack(
              children: [
                Column(
                  children: [
                    WorkbenchMenuBar(
                      compact: chrome.compact,
                      toolsOn: chrome.toolsVisible,
                      fileItems: [
                        WorkbenchMenuAction(
                          t.ble.saveLog,
                          cubit.saveLog,
                          kbd: t.serial.kbd.ctrlS,
                        ),
                      ],
                      toolItems: [
                        for (final tab in kBleToolTabs)
                          WorkbenchMenuAction(
                            _tabLabel(t, tab),
                            () => cubit.setTab(tab),
                          ),
                      ],
                      onCompact: () => cubit.setCompact(!chrome.compact),
                      onTools: () =>
                          cubit.setToolsVisible(!chrome.toolsVisible),
                      onKeys: () => showShortcutHelp(context),
                      onAbout: () => showSerialAbout(context),
                      compactLabel: t.ble.compact,
                      toolsLabel: t.ble.toolsPanel,
                      compactTip: t.ble.compactTip,
                      toolsTip: t.ble.toolsTip,
                    ),
                    if (widget.belowMenu != null) widget.belowMenu!,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            if (!chrome.compact) ...[
                              const SizedBox(
                                width: BleMetrics.sidebar,
                                child: BleSidePanel(),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child:
                                        BlocBuilder<
                                          BleConsoleCubit,
                                          BleConsoleState
                                        >(
                                          buildWhen: (a, b) =>
                                              a.lines != b.lines ||
                                              a.wrap != b.wrap ||
                                              a.autoScroll != b.autoScroll,
                                          builder: (context, state) {
                                            return BleLogView(
                                              state: state,
                                              search: _query,
                                              searchFocus: _searchFocus,
                                              onSearch: (value) => setState(
                                                () => _query = value,
                                              ),
                                            );
                                          },
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  const BleSendBox(),
                                ],
                              ),
                            ),
                            if (chrome.toolsVisible) ...[
                              const SizedBox(width: AppSpacing.sm),
                              const SizedBox(
                                width: SerialMetrics.tools,
                                child: BleToolsPanel(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const BleStatusBar(),
                  ],
                ),
                if (_toast != null)
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: SerialMetrics.statusBar + AppSpacing.md,
                    child: _Toast(notice: _toast!),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _tabLabel(Translations t, ToolTab tab) => switch (tab) {
  ToolTab.quick => t.serial.tab.quick,
  ToolTab.batch => t.serial.tab.batch,
  ToolTab.reply => t.serial.tab.reply,
  ToolTab.history => t.serial.tab.history,
  ToolTab.script => t.serial.tab.script,
  ToolTab.calc => t.serial.tab.quick,
};

class _Toast extends StatelessWidget {
  const _Toast({required this.notice});

  final BleNotice notice;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: notice.warn ? palette.off : palette.field,
      elevation: 8,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          bleNoticeText(Translations.of(context), notice),
          style: AppTextStyles.body(cs).copyWith(
            color: notice.warn ? Colors.white : palette.text,
          ),
        ),
      ),
    );
  }
}
