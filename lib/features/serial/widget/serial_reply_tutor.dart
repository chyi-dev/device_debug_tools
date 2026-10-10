import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../model/reply_lessons.dart';
import '../model/serial_models.dart';
import '../serial_metrics.dart';
import 'serial_chrome.dart';
import 'serial_l10n.dart';

/// 应答规则编辑器右侧的课表：点一课展开，填入只改左边的表单。
class ReplyTutorRail extends StatelessWidget {
  const ReplyTutorRail({
    super.key,
    required this.openKey,
    required this.wroteKey,
    required this.onToggle,
    required this.onFill,
  });

  final String? openKey;
  final String? wroteKey;
  final ValueChanged<String> onToggle;
  final ValueChanged<ReplyLesson> onFill;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final r = t.serial.reply;
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final groups = [
      (MatchKind.template, r.template),
      (MatchKind.regex, r.regex),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm + 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.tutor,
                style: AppTextStyles.body(cs).copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                r.tutorNote,
                style: AppTextStyles.caption(
                  cs,
                ).copyWith(color: palette.muted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: palette.line2),
        Expanded(
          child: ListView(
            children: [
              for (final group in groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm + 2,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    group.$2,
                    style: AppTextStyles.caption(cs).copyWith(
                      color: palette.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                for (final lesson in ReplyLesson.all)
                  if (lesson.kind == group.$1)
                    _Lesson(
                      index: ReplyLesson.all.indexOf(lesson) + 1,
                      lesson: lesson,
                      open: openKey == lesson.key,
                      wrote: wroteKey == lesson.key,
                      onToggle: () => onToggle(lesson.key),
                      onFill: () => onFill(lesson),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Lesson extends StatelessWidget {
  const _Lesson({
    required this.index,
    required this.lesson,
    required this.open,
    required this.wrote,
    required this.onToggle,
    required this.onFill,
  });

  final int index;
  final ReplyLesson lesson;
  final bool open;
  final bool wrote;
  final VoidCallback onToggle;
  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final copy = replyLessonCopy(t, lesson.key);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HoverSurface(
          color: open ? palette.hover : null,
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.line2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: AppSpacing.lg,
                      child: Text(
                        '$index',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.mono(
                          cs,
                          fontSize: 12,
                          color: palette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        copy.title,
                        style: AppTextStyles.body(cs).copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg + AppSpacing.sm,
                  ),
                  child: Text(
                    copy.brief,
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (open)
          ColoredBox(
            color: palette.panel,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl + AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.line2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.text,
                    style: AppTextStyles.body(
                      cs,
                    ).copyWith(color: palette.text, fontSize: 14, height: 1.6),
                  ),
                  if (lesson.modes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm + 2),
                    _ModeTable(lesson: lesson),
                  ],
                  const SizedBox(height: AppSpacing.sm + 2),
                  Text(
                    replyRecipe(t, lesson),
                    style: AppTextStyles.mono(
                      cs,
                      fontSize: 13,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  _Bytes(label: t.serial.reply.tutorRx, bytes: lesson.rx),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    copy.rxNote,
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Text(
                    t.serial.reply.tutorTx,
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted, fontSize: 12),
                  ),
                  for (var i = 0; i < lesson.replies.length; i++) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _Out(
                      delayMs: lesson.replies[i].delayMs,
                      sent: lesson.expected[i],
                      from: lesson.replies[i].data,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm + 2),
                  SerialButton(
                    label: t.serial.reply.tutorFill,
                    small: true,
                    primary: true,
                    onPressed: onFill,
                  ),
                  if (wrote) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.serial.reply.tutorWrote,
                      style: AppTextStyles.caption(cs).copyWith(
                        color: palette.accent,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Bytes extends StatelessWidget {
  const _Bytes({required this.label, required this.bytes});

  final String label;
  final List<ReplyByte> bytes;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(
            cs,
          ).copyWith(color: palette.muted, fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final byte in bytes)
              Container(
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.xxl + AppSpacing.sm,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 2,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: byte.role == ReplyByteRole.capture
                      ? palette.mark
                      : palette.field,
                  border: Border.all(
                    color: byte.role == ReplyByteRole.capture
                        ? Colors.transparent
                        : palette.line,
                  ),
                  borderRadius: BorderRadius.circular(
                    SerialMetrics.controlRadius,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      byte.text,
                      style: AppTextStyles.mono(
                        cs,
                        fontSize: 13,
                        color: byte.dim ? palette.muted : palette.text,
                        fontWeight: byte.dim
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      replyByteTag(t, byte),
                      style: AppTextStyles.caption(cs).copyWith(
                        color: byte.role == ReplyByteRole.capture
                            ? palette.text
                            : palette.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Out extends StatelessWidget {
  const _Out({required this.delayMs, required this.sent, required this.from});

  final int delayMs;
  final String sent;
  final String from;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: AppSpacing.lg * 4,
          child: Text(
            '+$delayMs ms',
            style: AppTextStyles.mono(cs, fontSize: 12, color: palette.muted),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sent,
                style: AppTextStyles.mono(
                  cs,
                  fontSize: 13,
                  color: palette.logTx,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                t.serial.reply.tutorFrom(from: from),
                style: AppTextStyles.caption(
                  cs,
                ).copyWith(color: palette.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeTable extends StatelessWidget {
  const _ModeTable({required this.lesson});

  final ReplyLesson lesson;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final r = t.serial.reply;
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    Text head(String text, {bool mono = false}) => Text(
      text,
      style: mono
          ? AppTextStyles.mono(cs, fontSize: 12, color: palette.muted)
          : AppTextStyles.caption(cs).copyWith(
              color: palette.muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
    );
    Widget cell(String text, {required bool hit}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        text,
        style: AppTextStyles.body(cs).copyWith(
          color: hit ? palette.text : palette.muted,
          fontWeight: hit ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
      ),
    );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(1.3),
        2: FlexColumnWidth(1.1),
      },
      children: [
        TableRow(
          children: [
            head(r.tutorWay),
            head(lesson.modeFrames[0], mono: true),
            head(lesson.modeFrames[1], mono: true),
          ],
        ),
        for (final row in lesson.modes)
          TableRow(
            children: [
              cell(matchModeLabel(t, row.mode), hit: true),
              cell(row.a ? r.tutorHit : r.tutorMiss, hit: row.a),
              cell(row.b ? r.tutorHit : r.tutorMiss, hit: row.b),
            ],
          ),
      ],
    );
  }
}
