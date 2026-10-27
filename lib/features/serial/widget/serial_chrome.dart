import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../serial_metrics.dart';

class SerialGroup extends StatelessWidget {
  const SerialGroup({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Padding(
        padding: SerialMetrics.groupPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(cs).copyWith(
                      color: palette.muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            child,
          ],
        ),
      ),
    );
  }
}

class SerialFieldRow extends StatelessWidget {
  const SerialFieldRow({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SerialMetrics.formGap),
      child: Row(
        children: [
          SizedBox(
            width: SerialMetrics.labelCol,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(
                Theme.of(context).colorScheme,
              ).copyWith(color: palette.muted, fontSize: 13),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class SerialButton extends StatelessWidget {
  const SerialButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = false,
    this.danger = false,
    this.alert = false,
    this.accent = false,
    this.small = false,
    this.expand = false,
    this.height,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;
  final bool alert;
  final bool accent;
  final bool small;
  final bool expand;
  final double? height;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final h =
        height ?? (small ? SerialMetrics.buttonSm : SerialMetrics.control);
    final bg = alert
        ? palette.off
        : primary
        ? palette.accent
        : palette.field;
    final fg = alert
        ? Colors.white
        : primary
        ? palette.accentInk
        : danger
        ? palette.off
        : accent
        ? palette.accent
        : palette.text;
    final border = alert || primary
        ? bg
        : accent
        ? palette.accent
        : palette.line;
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.body(cs).copyWith(
        color: fg,
        fontWeight: primary || alert || accent
            ? FontWeight.w600
            : FontWeight.w400,
        fontSize: small ? 13 : 14,
        height: 1,
      ),
    );
    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: onPressed == null ? bg.withValues(alpha: 0.6) : bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
      ),
      child: SizedBox(
        height: h,
        width: expand ? double.infinity : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: small ? AppSpacing.sm : AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              if (expand) Flexible(child: text) else text,
            ],
          ),
        ),
      ),
    );
    return MouseRegion(
      cursor: onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(onTap: onPressed, child: button),
    );
  }
}

class SerialField extends StatefulWidget {
  const SerialField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onFocusLost,
    this.enabled = true,
    this.mono = false,
    this.hint,
    this.height = SerialMetrics.control,
    this.maxLines = 1,
    this.expands = false,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFocusLost;
  final bool enabled;
  final bool mono;
  final String? hint;
  final double height;
  final int? maxLines;
  final bool expands;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<SerialField> createState() => _SerialFieldState();
}

class _SerialFieldState extends State<SerialField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  var _ownsFocus = false;

  @override
  void initState() {
    super.initState();
    _ownsFocus = widget.focusNode == null;
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focus.hasFocus) widget.onFocusLost?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final single = !widget.expands && widget.maxLines == 1;
    // 1.0 会让下划线贴在行框底边上，被裁掉。单行略放开，笔画留在框内。
    final lineHeight = single ? 1.2 : 1.4;
    final style = widget.mono
        ? AppTextStyles.mono(
            cs,
            fontSize: 14,
            height: lineHeight,
            color: palette.text,
          )
        : AppTextStyles.body(
            cs,
          ).copyWith(color: palette.text, height: lineHeight);
    final field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      maxLines: widget.expands ? null : widget.maxLines,
      expands: widget.expands,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      style: style,
      cursorColor: palette.accent,
      clipBehavior: Clip.hardEdge,
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: widget.hint,
        hintStyle: style.copyWith(color: palette.muted),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 6,
          vertical: single ? 1 : 4,
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.enabled ? palette.field : palette.panel,
        border: Border.all(
          color: _focus.hasFocus ? palette.accent : palette.line,
        ),
        borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
      ),
      child: SizedBox(
        height: widget.expands ? null : widget.height,
        child: single ? Center(child: field) : field,
      ),
    );
  }
}

class SerialDropdown<T> extends StatefulWidget {
  const SerialDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.height = SerialMetrics.controlSm,
  });

  final T value;
  final List<({T value, String label})> items;
  final ValueChanged<T>? onChanged;
  final bool enabled;
  final double height;

  @override
  State<SerialDropdown<T>> createState() => _SerialDropdownState<T>();
}

class _SerialDropdownState<T> extends State<SerialDropdown<T>> {
  final MenuController _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final active = widget.enabled && widget.onChanged != null;
    final style = AppTextStyles.body(cs).copyWith(
      color: active ? palette.text : palette.muted,
      fontSize: 13,
      height: 1,
    );
    String label = '';
    for (final item in widget.items) {
      if (item.value == widget.value) label = item.label;
    }
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth.isFinite ? box.maxWidth : 0.0;
        return MenuAnchor(
          controller: _menu,
          alignmentOffset: const Offset(0, 2),
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(palette.panel),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: AppSpacing.xs),
            ),
            minimumSize: WidgetStatePropertyAll(Size(width, 0)),
            maximumSize: WidgetStatePropertyAll(
              Size(
                width > SerialMetrics.menuMaxWidth
                    ? width
                    : SerialMetrics.menuMaxWidth,
                SerialMetrics.menuMaxHeight,
              ),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                side: BorderSide(color: palette.line),
                borderRadius: BorderRadius.circular(
                  SerialMetrics.controlRadius,
                ),
              ),
            ),
          ),
          menuChildren: [
            for (final item in widget.items)
              MenuItemButton(
                onPressed: () => widget.onChanged?.call(item.value),
                style: ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(
                    Size(width, widget.height),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  ),
                  visualDensity: VisualDensity.compact,
                  overlayColor: WidgetStatePropertyAll(palette.hover),
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.copyWith(
                    color: item.value == widget.value
                        ? palette.accent
                        : palette.text,
                    fontWeight: item.value == widget.value
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
          ],
          builder: (context, controller, _) {
            return MouseRegion(
              cursor: active
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                onTap: active
                    ? () => controller.isOpen
                          ? controller.close()
                          : controller.open()
                    : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: active ? palette.field : palette.panel,
                    border: Border.all(
                      color: controller.isOpen ? palette.accent : palette.line,
                    ),
                    borderRadius: BorderRadius.circular(
                      SerialMetrics.controlRadius,
                    ),
                  ),
                  child: SizedBox(
                    height: widget.height,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: style,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: active ? palette.muted : palette.line,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SerialLamp extends StatelessWidget {
  const SerialLamp({
    super.key,
    required this.color,
    this.size = SerialMetrics.lamp,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SerialMetrics.motion,
      curve: SerialMetrics.motionCurve,
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class SerialSwitch extends StatelessWidget {
  const SerialSwitch({super.key, required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SerialMetrics.motion,
        curve: SerialMetrics.motionCurve,
        width: 32,
        height: 18,
        decoration: BoxDecoration(
          color: on ? palette.on : palette.lampIdle,
          borderRadius: BorderRadius.circular(9),
        ),
        child: AnimatedAlign(
          duration: SerialMetrics.motion,
          curve: SerialMetrics.motionCurve,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class SerialCheck extends StatelessWidget {
  const SerialCheck({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: value,
                onChanged: (next) => onChanged(next ?? false),
              ),
            ),
            const SizedBox(width: AppSpacing.xs + 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(cs).copyWith(color: palette.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SerialLinkButton extends StatelessWidget {
  const SerialLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: danger ? palette.off : palette.muted,
        minimumSize: const Size(0, 24),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: AppTextStyles.caption(
          Theme.of(context).colorScheme,
        ).copyWith(fontSize: 13),
      ),
      child: Text(label),
    );
  }
}

/// 行操作右键菜单的一项；[danger] 用 off 色，删除仍由调用方走确认框。
class SerialMenuAction {
  const SerialMenuAction({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;
}

/// 在 [position] 弹出右键菜单，沿用菜单栏下拉的面板、描边与圆角；
/// 选中项在菜单完全关闭后才执行，打开对话框不会和菜单退场冲突。
Future<void> showSerialContextMenu(
  BuildContext context, {
  required Offset position,
  required List<SerialMenuAction> actions,
}) async {
  final palette = SerialPalette.of(context);
  final cs = Theme.of(context).colorScheme;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final index = await showMenu<int>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      overlay.size.width - position.dx,
      overlay.size.height - position.dy,
    ),
    color: palette.panel,
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: palette.line),
      borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
    ),
    items: [
      for (final (i, action) in actions.indexed)
        PopupMenuItem<int>(
          value: i,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 4),
          child: Text(
            action.label,
            style: AppTextStyles.body(cs).copyWith(
              fontSize: 13,
              color: action.danger ? palette.off : palette.text,
            ),
          ),
        ),
    ],
  );
  if (index != null) actions[index].onTap();
}

/// 给一整行挂右键菜单；行内主操作按钮不受影响。
class SerialContextMenu extends StatelessWidget {
  const SerialContextMenu({super.key, required this.menu, required this.child});

  final List<SerialMenuAction> menu;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: (details) => showSerialContextMenu(
        context,
        position: details.globalPosition,
        actions: menu,
      ),
      child: child,
    );
  }
}

class HoverSurface extends StatefulWidget {
  const HoverSurface({super.key, required this.child, this.color, this.onTap});

  final Widget child;
  final Color? color;
  final VoidCallback? onTap;

  @override
  State<HoverSurface> createState() => _HoverSurfaceState();
}

class _HoverSurfaceState extends State<HoverSurface> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ColoredBox(
          color: widget.color ?? (_hover ? palette.hover : Colors.transparent),
          child: widget.child,
        ),
      ),
    );
  }
}

class SerialFoldPane extends StatelessWidget {
  const SerialFoldPane({
    super.key,
    required this.visible,
    required this.width,
    required this.child,
    this.gapBefore = 0,
    this.gapAfter = 0,
  });

  final bool visible;
  final double width;
  final Widget child;
  final double gapBefore;
  final double gapAfter;

  @override
  Widget build(BuildContext context) {
    final total = width + gapBefore + gapAfter;
    return ClipRect(
      child: AnimatedAlign(
        duration: SerialMetrics.motion,
        curve: SerialMetrics.motionCurve,
        alignment: gapAfter > 0 ? Alignment.centerLeft : Alignment.centerRight,
        widthFactor: visible ? 1 : 0,
        heightFactor: 1,
        child: SizedBox(
          width: total,
          child: Row(
            children: [
              if (gapBefore > 0) SizedBox(width: gapBefore),
              SizedBox(width: width, child: child),
              if (gapAfter > 0) SizedBox(width: gapAfter),
            ],
          ),
        ),
      ),
    );
  }
}

class SerialItemRow extends StatelessWidget {
  const SerialItemRow({
    super.key,
    this.leading,
    required this.title,
    required this.detail,
    this.trailing = const [],
    this.monoTitle = false,
    this.indent = false,
    this.menu,
    this.color,
  });

  final Widget? leading;
  final String title;
  final String detail;
  final List<Widget> trailing;
  final bool monoTitle;
  final bool indent;
  final List<SerialMenuAction>? menu;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final menu = this.menu;
    final row = HoverSurface(
      color: color,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm + 2 + (indent ? AppSpacing.lg : 0),
          AppSpacing.sm,
          AppSpacing.sm + 2,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.line2)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.sm + 2),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: monoTitle
                        ? AppTextStyles.mono(
                            cs,
                            fontSize: 13,
                            color: palette.text,
                          )
                        : AppTextStyles.body(cs).copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mono(
                      cs,
                      fontSize: 12,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            ...trailing,
          ],
        ),
      ),
    );
    return menu == null ? row : SerialContextMenu(menu: menu, child: row);
  }
}

class SerialKeyChip extends StatelessWidget {
  const SerialKeyChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: AppTextStyles.mono(
          Theme.of(context).colorScheme,
          fontSize: 12,
          color: palette.muted,
        ),
      ),
    );
  }
}

class SerialSectionLabel extends StatelessWidget {
  const SerialSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(Theme.of(context).colorScheme).copyWith(
          color: palette.muted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class SerialToolBar extends StatelessWidget {
  const SerialToolBar({
    super.key,
    required this.note,
    this.actions = const [],
    this.leading,
  });

  final String note;
  final List<Widget> actions;

  /// 工具条左侧的分段控件，例如脚本页的「我的 / 教程」。
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final leading = this.leading;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line2)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              note,
              style: AppTextStyles.caption(
                Theme.of(context).colorScheme,
              ).copyWith(color: palette.muted),
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(width: AppSpacing.xs + 2),
            action,
          ],
        ],
      ),
    );
  }
}

class SerialSearchField extends StatelessWidget {
  const SerialSearchField({
    super.key,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
  });

  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: SerialMetrics.searchWidth,
      child: TextField(
        focusNode: focusNode,
        onChanged: onChanged,
        style: AppTextStyles.body(
          cs,
        ).copyWith(color: palette.text, fontSize: 13, height: 1),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: AppTextStyles.body(
            cs,
          ).copyWith(color: palette.muted, fontSize: 13, height: 1),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          filled: true,
          fillColor: palette.field,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
            borderSide: BorderSide(color: palette.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
            borderSide: BorderSide(color: palette.line),
          ),
        ),
      ),
    );
  }
}

class SerialNoticeToast extends StatelessWidget {
  const SerialNoticeToast({super.key, required this.text, required this.warn});

  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final bg = warn ? palette.off : palette.text;
    final fg = warn ? Colors.white : palette.win;
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
          text,
          style: AppTextStyles.body(
            Theme.of(context).colorScheme,
          ).copyWith(color: fg),
        ),
      ),
    );
  }
}

class SerialNoticeOverlay extends StatelessWidget {
  const SerialNoticeOverlay({
    super.key,
    required this.visible,
    required this.text,
    required this.warn,
  });

  final bool visible;
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: SerialMetrics.statusBar + AppSpacing.md,
      child: IgnorePointer(
        child: Center(
          child: AnimatedSwitcher(
            duration: SerialMetrics.motion,
            switchInCurve: SerialMetrics.motionCurve,
            switchOutCurve: SerialMetrics.motionCurve,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 8 * (1 - animation.value)),
                      child: child,
                    );
                  },
                  child: child,
                ),
              );
            },
            child: visible
                ? SerialNoticeToast(key: ValueKey(text), text: text, warn: warn)
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ),
    );
  }
}
