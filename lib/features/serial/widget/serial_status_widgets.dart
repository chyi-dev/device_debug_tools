import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../i18n/i18n.dart';
import '../serial_metrics.dart';

/// 状态栏提示区域，测试用。
const serialStatusHintKey = Key('status-hint');

class SerialStatusCell extends StatelessWidget {
  const SerialStatusCell({super.key, required this.child, this.last = false});

  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return Container(
      height: SerialMetrics.statusBar,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          left: last ? BorderSide(color: palette.line2) : BorderSide.none,
          right: last ? BorderSide.none : BorderSide(color: palette.line2),
        ),
      ),
      child: child,
    );
  }
}

class SerialStatusCount extends StatelessWidget {
  const SerialStatusCount(this.label, this.value, {super.key});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
        children: [
          TextSpan(
            text: '$value',
            style: AppTextStyles.mono(
              cs,
              fontSize: 12,
              color: palette.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SerialStatusTextButton extends StatelessWidget {
  const SerialStatusTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: AppTextStyles.caption(cs),
      ),
      child: Text(label),
    );
  }
}

class SerialStatusHint extends StatelessWidget {
  const SerialStatusHint({
    super.key,
    required this.text,
    required this.showCopy,
  });

  final String text;
  final bool showCopy;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return SerialStatusCell(
      last: true,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
            ),
          ),
          if (showCopy) ...[
            const SizedBox(width: AppSpacing.sm),
            SerialStatusTextButton(
              label: t.serial.status.copy,
              onPressed: () => _copy(context, text),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    AppSnackBar.info(context, Translations.of(context).serial.status.copied);
  }
}
