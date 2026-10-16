import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/serial_console_cubit.dart';
import '../cubit/serial_console_state.dart';
import '../model/serial_models.dart';
import '../serial_metrics.dart';
import '../widget/serial_config_dialog.dart';
import '../widget/serial_editors.dart';
import '../widget/serial_l10n.dart';
import '../widget/serial_log_view.dart';
import '../widget/serial_menu_bar.dart';
import '../widget/serial_script_dock.dart';
import '../widget/serial_send_box.dart';
import '../widget/serial_side_panel.dart';
import '../widget/serial_status_bar.dart';
import '../widget/serial_tools_panel.dart';

class SerialConsoleView extends StatefulWidget {
  const SerialConsoleView({
    super.key,
    this.belowMenu,
    this.shortcutsEnabled = true,
  });

  /// 放在菜单栏下方，例如首页连接页签。
  final Widget? belowMenu;

  /// 只有当前页签响应全局快捷键。
  final bool shortcutsEnabled;

  @override
  State<SerialConsoleView> createState() => _SerialConsoleViewState();
}

class _SerialConsoleViewState extends State<SerialConsoleView> {
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  Timer? _toastTimer;
  SerialNotice? _toast;
  var _narrowApplied = false;

  @override
  void initState() {
    super.initState();
    if (widget.shortcutsEnabled) {
      HardwareKeyboard.instance.addHandler(_onKey);
    }
  }

  @override
  void didUpdateWidget(SerialConsoleView oldWidget) {
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
      context.read<SerialConsoleCubit>().setCompact(true);
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
    final cubit = context.read<SerialConsoleCubit>();
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
      cubit.stopLoop();
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

  void _showToast(SerialNotice notice) {
    _toastTimer?.cancel();
    setState(() => _toast = notice);
    _toastTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return Scaffold(
      backgroundColor: palette.win,
      body: BlocListener<SerialConsoleCubit, SerialConsoleState>(
        listenWhen: (previous, current) =>
            previous.toast?.id != current.toast?.id,
        listener: (context, state) {
          final toast = state.toast;
          if (toast != null) _showToast(toast);
        },
        child: BlocBuilder<SerialConsoleCubit, SerialConsoleState>(
          buildWhen: (previous, current) =>
              previous.compact != current.compact ||
              previous.toolsVisible != current.toolsVisible ||
              previous.tab != current.tab ||
              previous.scriptDockVisible != current.scriptDockVisible,
          builder: (context, chrome) {
            final cubit = context.read<SerialConsoleCubit>();
            return Stack(
              children: [
                Column(
                  children: [
                    SerialMenuBar(
                      compact: chrome.compact,
                      toolsOn: chrome.toolsVisible,
                      onSave: cubit.saveLog,
                      onExportConfig: () => showConfigExport(context),
                      onImportConfig: () => showConfigImport(context),
                      onCompact: () => cubit.setCompact(!chrome.compact),
                      onTools: () =>
                          cubit.setToolsVisible(!chrome.toolsVisible),
                      onTab: cubit.setTab,
                      onKeys: () => showShortcutHelp(context),
                      onAbout: () => showSerialAbout(context),
                    ),
                    if (widget.belowMenu != null) widget.belowMenu!,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            if (!chrome.compact) ...[
                              SizedBox(
                                width: SerialMetrics.sidebar,
                                child: const SerialSidePanel(),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child:
                                        BlocBuilder<
                                          SerialConsoleCubit,
                                          SerialConsoleState
                                        >(
                                          buildWhen: (previous, current) =>
                                              previous.lines != current.lines ||
                                              previous.rxFormat !=
                                                  current.rxFormat ||
                                              previous.logMode !=
                                                  current.logMode ||
                                              previous.wrap != current.wrap ||
                                              previous.hideRx !=
                                                  current.hideRx ||
                                              previous.autoScroll !=
                                                  current.autoScroll ||
                                              previous.open != current.open,
                                          builder: (context, state) {
                                            return SerialLogView(
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
                                  if (chrome.scriptDockVisible) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    const SizedBox(
                                      height: SerialMetrics.scriptDock,
                                      child: SerialScriptDock(),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.sm),
                                  const SerialSendBox(),
                                ],
                              ),
                            ),
                            if (chrome.toolsVisible) ...[
                              const SizedBox(width: AppSpacing.sm),
                              const SizedBox(
                                width: SerialMetrics.tools,
                                child: SerialToolsPanel(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SerialStatusBar(),
                  ],
                ),
                if (_toast != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 44,
                    child: IgnorePointer(
                      child: Center(child: _Toast(notice: _toast!)),
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

class _Toast extends StatelessWidget {
  const _Toast({required this.notice});

  final SerialNotice notice;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final bg = notice.warn ? palette.off : palette.text;
    final fg = notice.warn ? Colors.white : palette.win;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 1,
        ),
        child: Text(
          serialNoticeText(t, notice),
          style: AppTextStyles.body(
            Theme.of(context).colorScheme,
          ).copyWith(color: fg),
        ),
      ),
    );
  }
}
