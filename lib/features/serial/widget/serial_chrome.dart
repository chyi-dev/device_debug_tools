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
  final bool small;
  final bool expand;
  final double? height;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final h = height ?? (small ? SerialMetrics.buttonSm : SerialMetrics.control);
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
                : palette.text;
    final border = alert || primary ? bg : palette.line;
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
          padding: EdgeInsets.symmetric(horizontal: small ? AppSpacing.sm : AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: AppTextStyles.body(cs).copyWith(
                  color: fg,
                  fontWeight: primary || alert ? FontWeight.w600 : FontWeight.w400,
                  fontSize: small ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return MouseRegion(
      cursor: onPressed == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
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
    final style = widget.mono
        ? AppTextStyles.mono(cs, fontSize: 14, height: 1.4, color: palette.text)
        : AppTextStyles.body(cs).copyWith(color: palette.text);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.enabled ? palette.field : palette.panel,
        border: Border.all(color: _focus.hasFocus ? palette.accent : palette.line),
        borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
      ),
      child: SizedBox(
        height: widget.expands ? null : widget.height,
        child: TextField(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
          ),
        ),
      ),
    );
  }
}

class SerialDropdown<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? palette.field : palette.panel,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
      ),
      child: SizedBox(
        height: height,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.any((item) => item.value == value) ? value : null,
            isExpanded: true,
            isDense: true,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            dropdownColor: palette.panel,
            style: AppTextStyles.body(cs).copyWith(color: palette.text, fontSize: 13),
            items: [
              for (final item in items)
                DropdownMenuItem(value: item.value, child: Text(item.label)),
            ],
            onChanged: enabled
                ? (next) {
                    if (next != null) onChanged?.call(next);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class SerialLamp extends StatelessWidget {
  const SerialLamp({super.key, required this.color, this.size = SerialMetrics.lamp});

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
        textStyle: AppTextStyles.caption(Theme.of(context).colorScheme).copyWith(
          fontSize: 13,
        ),
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
