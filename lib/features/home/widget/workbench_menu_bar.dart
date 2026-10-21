import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';

import '../../../app/cubit/app_cubit.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../core/widgets/app_window_caption.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';

class WorkbenchMenuAction {
  const WorkbenchMenuAction(this.label, this.onPressed, {this.kbd});

  final String label;
  final VoidCallback onPressed;
  final String? kbd;
}

/// 多协议调试台共用菜单栏：文件项由调用方提供，不含串口配置包。
class WorkbenchMenuBar extends StatelessWidget {
  const WorkbenchMenuBar({
    super.key,
    required this.compact,
    required this.toolsOn,
    required this.fileItems,
    required this.toolItems,
    required this.onCompact,
    required this.onTools,
    required this.onKeys,
    required this.onAbout,
    required this.compactLabel,
    required this.toolsLabel,
    required this.compactTip,
    required this.toolsTip,
  });

  final bool compact;
  final bool toolsOn;
  final List<WorkbenchMenuAction> fileItems;
  final List<WorkbenchMenuAction> toolItems;
  final VoidCallback onCompact;
  final VoidCallback onTools;
  final VoidCallback onKeys;
  final VoidCallback onAbout;
  final String compactLabel;
  final String toolsLabel;
  final String compactTip;
  final String toolsTip;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final menu = t.serial.menu;
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
                              _Menu(label: menu.file, items: fileItems),
                              _Menu(
                                label: menu.settings,
                                items: [
                                  WorkbenchMenuAction(
                                    menu.themeLight,
                                    () => context.read<AppCubit>().setThemeMode(
                                      ThemeMode.light,
                                    ),
                                  ),
                                  WorkbenchMenuAction(
                                    menu.themeDark,
                                    () => context.read<AppCubit>().setThemeMode(
                                      ThemeMode.dark,
                                    ),
                                  ),
                                  WorkbenchMenuAction(
                                    menu.compact,
                                    onCompact,
                                  ),
                                  WorkbenchMenuAction(
                                    menu.toolsPanel,
                                    onTools,
                                  ),
                                ],
                              ),
                              _Menu(label: menu.tools, items: toolItems),
                              _Menu(
                                label: menu.help,
                                items: [
                                  WorkbenchMenuAction(
                                    menu.keys,
                                    onKeys,
                                    kbd: t.serial.kbd.f12,
                                  ),
                                  WorkbenchMenuAction(menu.about, onAbout),
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
                label: compactLabel,
                tip: compactTip,
                on: compact,
                onPressed: onCompact,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              _IconToggle(
                label: toolsLabel,
                tip: toolsTip,
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

class _Menu extends StatelessWidget {
  const _Menu({required this.label, required this.items});

  final String label;
  final List<WorkbenchMenuAction> items;

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
            color: on ? palette.field : Colors.transparent,
            border: Border.all(color: on ? palette.line : Colors.transparent),
            borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.caption(
              cs,
            ).copyWith(color: on ? palette.text : palette.muted, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
