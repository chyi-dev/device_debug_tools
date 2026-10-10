import 'dart:math' as math;

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
    this.side,
    this.titleTrailing,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  /// 标题行右侧的控件，例如应答规则的「教程」开关。
  final Widget? titleTrailing;

  /// 放在表单右侧，例如应答规则的课表。有侧栏时对话框加宽并撑到固定高度。
  final Widget? side;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final screen = MediaQuery.sizeOf(context);
    final tutor = side != null;
    final dialogW = math.min(
      screen.width * (tutor ? 0.96 : 0.92),
      tutor ? SerialMetrics.dialogTutorWidth : SerialMetrics.dialogWidth,
    );
    final maxH = screen.height * (tutor ? 0.92 : 0.86);
    final dialogH = tutor
        ? math.min(SerialMetrics.dialogTutorHeight, maxH)
        : null;
    final railW = math.min(SerialMetrics.tutorRail, dialogW * 0.42);
    final form = SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      child: body,
    );
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: tutor ? dialogW : 0,
          maxWidth: dialogW,
          minHeight: dialogH ?? 0,
          maxHeight: dialogH ?? maxH,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border.all(color: palette.line),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            mainAxisSize: tutor ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg + 2,
                  AppSpacing.md + 2,
                  AppSpacing.lg + 2,
                  AppSpacing.md + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.body(cs).copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    ?titleTrailing,
                  ],
                ),
              ),
              Divider(height: 1, color: palette.line2),
              Flexible(
                child: tutor
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: form),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: palette.win,
                              border: Border(
                                left: BorderSide(color: palette.line),
                              ),
                            ),
                            child: SizedBox(width: railW, child: side),
                          ),
                        ],
                      )
                    : form,
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
