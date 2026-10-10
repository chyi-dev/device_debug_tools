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
    final lineHeight = single ? 1.0 : 1.4;
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
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: widget.hint,
        hintStyle: style.copyWith(color: palette.muted),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 6,
          vertical: single ? 0 : 4,
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
    return Container(
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
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 18,
        decoration: BoxDecoration(
          color: on ? palette.on : palette.lampIdle,
          borderRadius: BorderRadius.circular(9),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
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
            Expanded(
              child: Text(
                label,
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
