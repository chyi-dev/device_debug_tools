import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';

import '../../../app/cubit/app_cubit.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../core/widgets/app_window_caption.dart';
import '../../../i18n/i18n.dart';
import '../../home/widget/appreciate_dialog.dart';
import '../../license/widget/license_dialogs.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../../update/cubit/update_cubit.dart';

class SocketMenuBar extends StatelessWidget {
  const SocketMenuBar({
    super.key,
    required this.compact,
    required this.toolsOn,
    required this.onSave,
    required this.onCompact,
    required this.onTools,
    required this.onTab,
    required this.onKeys,
    required this.onAbout,
  });

  final bool compact;
  final bool toolsOn;
  final VoidCallback onSave;
  final VoidCallback onCompact;
  final VoidCallback onTools;
  final ValueChanged<ToolTab> onTab;
  final VoidCallback onKeys;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final menu = t.socket.menu;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: SizedBox(
        height: SerialMetrics.menuBar,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              DragToMoveArea(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: AppSpacing.xs,
                                    right: AppSpacing.md,
                                  ),
                                  child: Row(
                                    children: [
                                      const AppWindowIcon(),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        t.app.title,
                                        style: AppTextStyles.body(cs).copyWith(
                                          color: palette.text,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _Menu(
                                label: menu.file,
                                items: [
                                  _Item(
                                    menu.saveLog,
                                    onSave,
                                    kbd: t.socket.kbd.ctrlS,
                                  ),
                                ],
                              ),
                              _Menu(
                                label: menu.settings,
                                items: [
                                  _Item(
                                    menu.themeLight,
                                    () => context.read<AppCubit>().setThemeMode(
                                      ThemeMode.light,
                                    ),
                                    checked: light,
                                  ),
                                  _Item(
                                    menu.themeDark,
                                    () => context.read<AppCubit>().setThemeMode(
                                      ThemeMode.dark,
                                    ),
                                    checked: !light,
                                  ),
                                  const _Item.gap(),
                                  _Item(
                                    menu.compact,
                                    onCompact,
                                    checked: compact,
                                  ),
                                  _Item(
                                    menu.toolsPanel,
                                    onTools,
                                    checked: toolsOn,
                                  ),
                                ],
                              ),
                              _Menu(
                                label: menu.tools,
                                items: [
                                  for (final tab in const [
                                    ToolTab.quick,
                                    ToolTab.batch,
                                    ToolTab.reply,
                                    ToolTab.history,
                                    ToolTab.script,
                                  ])
                                    _Item(_tabLabel(t, tab), () => onTab(tab)),
                                ],
                              ),
                              _Menu(
                                label: menu.help,
                                items: [
                                  _Item(
                                    menu.keys,
                                    onKeys,
                                    kbd: t.socket.kbd.f12,
                                  ),
                                  _Item(
                                    menu.checkUpdate,
                                    () => context
                                        .read<UpdateCubit>()
                                        .checkManual(),
                                  ),
                                  _Item(
                                    menu.activate,
                                    () => showLicenseActivateDialog(context),
                                  ),
                                  _Item(
                                    menu.appreciate,
                                    () => showAppreciateDialog(context),
                                  ),
                                  _Item(menu.about, onAbout),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Expanded(
                        child: DragToMoveArea(child: SizedBox.expand()),
                      ),
                    ],
                  ),
                ),
              ),
              _IconToggle(
                label: t.socket.compact,
                tip: t.socket.compactTip,
                on: compact,
                onPressed: onCompact,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              _IconToggle(
                label: t.socket.toolsPanel,
                tip: t.socket.toolsTip,
                on: toolsOn,
                onPressed: onTools,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppWindowButtons(
                height: SerialMetrics.menuBar,
                foreground: palette.text,
                hover: palette.hover,
              ),
            ],
          ),
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
  ToolTab.calc => t.serial.tab.quick,
  ToolTab.script => t.serial.tab.script,
};

class _Item {
  const _Item(this.label, this.onPressed, {this.kbd, this.checked = false})
    : gap = false;

  const _Item.gap()
    : label = '',
      onPressed = null,
      kbd = null,
      checked = false,
      gap = true;

  final String label;
  final VoidCallback? onPressed;
  final String? kbd;
  final bool checked;
  final bool gap;
}

class _Menu extends StatelessWidget {
  const _Menu({required this.label, required this.items});

  final String label;
  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(palette.panel),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            side: BorderSide(color: palette.line),
          ),
        ),
      ),
      menuChildren: [
        for (final item in items)
          if (item.gap)
            Divider(height: AppSpacing.sm, color: palette.line2)
          else
            MenuItemButton(
              onPressed: item.onPressed,
              child: SizedBox(
                width: 220,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTextStyles.body(
                          cs,
                        ).copyWith(color: palette.text),
                      ),
                    ),
                    if (item.kbd != null)
                      Text(
                        item.kbd!,
                        style: AppTextStyles.mono(
                          cs,
                          fontSize: 12,
                          color: palette.muted,
                        ),
                      ),
                    if (item.checked)
                      Text(
                        '✓',
                        style: AppTextStyles.body(
                          cs,
                        ).copyWith(color: palette.muted),
                      ),
                  ],
                ),
              ),
            ),
      ],
      builder: (context, controller, child) {
        final open = controller.isOpen;
        return InkWell(
          onTap: () => open ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: open ? palette.hover : Colors.transparent,
              borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.body(cs).copyWith(color: palette.text),
            ),
          ),
        );
      },
    );
  }
}

class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.label,
    required this.tip,
    required this.on,
    required this.onPressed,
  });

  final String label;
  final String tip;
  final bool on;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: on ? palette.hover : Colors.transparent,
            border: Border.all(
              color: on ? palette.accentBorder : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.caption(
              cs,
            ).copyWith(color: on ? palette.accent : palette.muted, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
