import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../serial_metrics.dart';

Future<T?> showSerialDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color.fromRGBO(10, 14, 20, 0.38),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(child: Builder(builder: builder));
    },
  );
}

class SerialDialogFrame extends StatelessWidget {
  const SerialDialogFrame({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width * 0.92 < SerialMetrics.dialogWidth
              ? width * 0.92
              : SerialMetrics.dialogWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border.all(color: palette.line),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg + 2,
                  AppSpacing.md + 2,
                  AppSpacing.lg + 2,
                  AppSpacing.md + 2,
                ),
                child: Text(
                  title,
                  style: AppTextStyles.body(cs).copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Divider(height: 1, color: palette.line2),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg + 2),
                  child: body,
                ),
              ),
              Divider(height: 1, color: palette.line2),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SerialDialogError extends StatelessWidget {
  const SerialDialogError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return SizedBox(
      height: 18,
      child: Text(
        message,
        style: AppTextStyles.caption(
          Theme.of(context).colorScheme,
        ).copyWith(color: palette.off, fontSize: 13),
      ),
    );
  }
}
