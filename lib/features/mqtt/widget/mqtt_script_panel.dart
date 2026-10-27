import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';
import '../../serial/widget/serial_editors.dart';
import '../cubit/mqtt_console_cubit.dart';
import '../cubit/mqtt_console_state.dart';
import '../model/mqtt_models.dart';
import '../model/mqtt_script_lessons.dart';

class MqttScriptPanel extends StatelessWidget {
  const MqttScriptPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      buildWhen: (a, b) =>
          a.scripts != b.scripts ||
          a.scriptMeta != b.scriptMeta ||
          a.scriptTutorial != b.scriptTutorial ||
          a.openLesson != b.openLesson ||
          a.selectedScriptId != b.selectedScriptId ||
          a.scriptDock != b.scriptDock,
      builder: (context, state) {
        final t = Translations.of(context);
        final s = t.mqtt.script;
        final cubit = context.read<MqttConsoleCubit>();
        final enabled = state.scripts.where((item) => item.enabled).length;
        final views = _ViewSwitch(
          tutorial: state.scriptTutorial,
          mineLabel: s.mine(count: state.scripts.length),
          tutorialLabel: s.tutorial,
          onChanged: cubit.setScriptTutorial,
        );
        if (state.scriptTutorial) {
          return Column(
            children: [
              SerialToolBar(
                leading: views,
                note: s.note(enabled: enabled, total: state.scripts.length),
                actions: const [],
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final (i, lesson) in MqttScriptLesson.all.indexed)
                      _LessonRow(
                        index: i + 1,
                        lesson: lesson,
                        open: state.openLesson == lesson.key,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        s.tutorialNote,
                        style: AppTextStyles.caption(
                          Theme.of(context).colorScheme,
                        ).copyWith(color: SerialPalette.of(context).muted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        final current = state.scriptDockVisible ? state.selectedScript : null;
        return Column(
          children: [
            SerialToolBar(
              leading: views,
              note: s.note(enabled: enabled, total: state.scripts.length),
              actions: [
                SerialButton(
                  label: s.add,
                  small: true,
                  onPressed: cubit.newScript,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final script in state.scripts)
                    _ScriptRow(
                      script: script,
                      meta:
                          state.scriptMeta[script.id] ?? const MqttScriptMeta(),
                      active: script.id == current?.id,
                    ),
                  if (state.scripts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        s.empty,
                        style: AppTextStyles.caption(
                          Theme.of(context).colorScheme,
                        ).copyWith(color: SerialPalette.of(context).muted),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      s.explain,
                      style: AppTextStyles.caption(
                        Theme.of(context).colorScheme,
                      ).copyWith(color: SerialPalette.of(context).muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScriptRow extends StatelessWidget {
  const _ScriptRow({
    required this.script,
    required this.meta,
    required this.active,
  });

  final LuaScript script;
  final MqttScriptMeta meta;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final s = t.mqtt.script;
    final cubit = context.read<MqttConsoleCubit>();
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final status = meta.outputs > 0
        ? s.outputs(count: meta.outputs)
        : (script.enabled ? s.waiting : s.off);
    return SerialContextMenu(
      menu: [
        SerialMenuAction(
          label: s.rename,
          onTap: () => showMqttScriptRename(context, script),
        ),
        SerialMenuAction(
          label: t.common.duplicate,
          onTap: () => cubit.duplicateScript(script.id),
        ),
        SerialMenuAction(
          label: t.common.delete,
          danger: true,
          onTap: () => showSerialDelete(
            context,
            message: s.delete(name: script.name),
            onDelete: () => cubit.deleteScript(script.id),
          ),
        ),
      ],
      child: HoverSurface(
        color: active ? palette.accent.withValues(alpha: 0.14) : null,
        onTap: () => cubit.selectScript(script.id),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.line2)),
          ),
          child: Row(
            children: [
              SerialSwitch(
                on: script.enabled,
                onTap: () => cubit.toggleScript(script.id),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      script.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(cs).copyWith(
                        color: script.enabled ? palette.text : palette.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ..._hookChips(context, meta),
                        Expanded(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.mono(
                              cs,
                              fontSize: 12,
                              color: palette.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
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

List<Widget> mqttHookChips(BuildContext context, MqttScriptMeta meta) =>
    _hookChips(context, meta);

List<Widget> _hookChips(BuildContext context, MqttScriptMeta meta) {
  final s = Translations.of(context).mqtt.script;
  final palette = SerialPalette.of(context);
  if (meta.error != null) {
    return [
      Tooltip(
        message: meta.error!,
        child: _Chip(s.broken, color: palette.off),
      ),
    ];
  }
  if (meta.hooks.isEmpty) return [_Chip(s.noHook)];
  return [for (final hook in meta.hooks) _Chip(_hookName(context, hook))];
}

String _hookName(BuildContext context, MqttScriptHook hook) {
  final s = Translations.of(context).mqtt.script;
  return switch (hook) {
    MqttScriptHook.onMessage => s.hookMessage,
    MqttScriptHook.beforePublish => s.hookPublish,
  };
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final tone = color ?? palette.muted;
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs + 2),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color ?? palette.line),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: AppTextStyles.mono(
          Theme.of(context).colorScheme,
          fontSize: 12,
          color: tone,
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.open,
  });

  final int index;
  final MqttScriptLesson lesson;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final s = t.mqtt.script;
    final lessons = s.lessons;
    final title = switch (lesson.key) {
      'hooks' => lessons.hooks.title,
      'print' => lessons.print.title,
      _ => lessons.rewrite.title,
    };
    final text = switch (lesson.key) {
      'hooks' => lessons.hooks.text,
      'print' => lessons.print.text,
      _ => lessons.rewrite.text,
    };
    final cubit = context.read<MqttConsoleCubit>();
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => cubit.toggleLesson(lesson.key),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  '$index',
                  style: AppTextStyles.mono(
                    cs,
                    fontSize: 12,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body(cs).copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _Chip(lesson.hookName),
              ],
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  text,
                  style: AppTextStyles.caption(
                    cs,
                  ).copyWith(color: palette.muted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  lesson.code,
                  style: AppTextStyles.mono(
                    cs,
                    fontSize: 12,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    SerialButton(
                      label: s.lessonNew,
                      small: true,
                      primary: true,
                      onPressed: () => cubit.newScriptFromLesson(lesson),
                    ),
                    SerialButton(
                      label: s.lessonTry,
                      small: true,
                      onPressed: () => cubit.tryLesson(lesson),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Divider(height: 1, color: palette.line2),
      ],
    );
  }
}

class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({
    required this.tutorial,
    required this.mineLabel,
    required this.tutorialLabel,
    required this.onChanged,
  });

  final bool tutorial;
  final String mineLabel;
  final String tutorialLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    Widget segment(String label, bool value) {
      final on = tutorial == value;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            height: SerialMetrics.buttonSm,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
            color: on ? palette.accent : palette.field,
            child: Text(
              label,
              style: AppTextStyles.body(cs).copyWith(
                fontSize: 13,
                height: 1,
                color: on ? palette.accentInk : palette.muted,
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(mineLabel, false),
          Container(
            width: 1,
            height: SerialMetrics.buttonSm,
            color: palette.line,
          ),
          segment(tutorialLabel, true),
        ],
      ),
    );
  }
}

Future<void> showMqttScriptRename(BuildContext context, LuaScript script) {
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => _RenameDialog(script: script),
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.script});

  final LuaScript script;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.script.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return SerialDialogFrame(
      title: t.mqtt.script.renameTitle,
      body: SerialField(controller: _name),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        SerialButton(
          label: t.common.save,
          primary: true,
          onPressed: () {
            context.read<MqttConsoleCubit>().renameScript(
              widget.script.id,
              _name.text,
            );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
