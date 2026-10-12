import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/serial_console_cubit.dart';
import '../cubit/serial_console_state.dart';
import '../data/serial_bytes.dart';
import '../data/serial_stamp.dart';
import '../model/script_lessons.dart';
import '../model/serial_models.dart';
import '../serial_metrics.dart';
import 'serial_chrome.dart';
import 'serial_editors.dart';
import 'serial_l10n.dart';
import 'serial_script_dock.dart';

class SerialToolsPanel extends StatefulWidget {
  const SerialToolsPanel({super.key});

  @override
  State<SerialToolsPanel> createState() => _SerialToolsPanelState();
}

class _SerialToolsPanelState extends State<SerialToolsPanel> {
  DataFormat _calcFormat = DataFormat.hex;
  final TextEditingController _calc = TextEditingController(
    text: 'A5 5A 03 00 F6 02 09',
  );

  @override
  void dispose() {
    _calc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return BlocBuilder<SerialConsoleCubit, SerialConsoleState>(
      builder: (context, state) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border.all(color: palette.line),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 38,
                child: Row(
                  children: [
                    for (final tab in ToolTab.values)
                      if (tab == ToolTab.script) ...[
                        // 脚本页会改动中间列，用竖线与其他页签隔开
                        const SizedBox(width: AppSpacing.xs),
                        Container(width: 1, height: 18, color: palette.line),
                        const SizedBox(width: AppSpacing.xs),
                        _tabButton(context, state, tab, padded: true),
                      ] else
                        Expanded(child: _tabButton(context, state, tab)),
                  ],
                ),
              ),
              Divider(height: 1, color: palette.line),
              Expanded(child: _body(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _tabButton(
    BuildContext context,
    SerialConsoleState state,
    ToolTab tab, {
    bool padded = false,
  }) {
    final palette = SerialPalette.of(context);
    final active = state.tab == tab;
    return InkWell(
      onTap: () => context.read<SerialConsoleCubit>().setTab(tab),
      child: Container(
        padding: padded
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? palette.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _tabLabel(Translations.of(context), tab),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(Theme.of(context).colorScheme).copyWith(
            color: active ? palette.text : palette.muted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SerialConsoleState state) {
    return switch (state.tab) {
      ToolTab.script => _ScriptTab(state: state),
      ToolTab.quick => _QuickTab(state: state),
      ToolTab.batch => _BatchTab(state: state),
      ToolTab.reply => _ReplyTab(state: state),
      ToolTab.history => _HistoryTab(state: state),
      ToolTab.calc => _CalcTab(
        format: _calcFormat,
        controller: _calc,
        onFormat: (format) => setState(() => _calcFormat = format),
        onUseTx: () {
          final file = state.fileBytes;
          final text = file != null ? SerialBytes.toHex(file) : state.txText;
          final format = file != null ? DataFormat.hex : state.txFormat;
          setState(() {
            _calcFormat = format;
            _calc.text = text;
          });
        },
        onEdited: () => setState(() {}),
      ),
    };
  }
}

String _tabLabel(Translations t, ToolTab tab) => switch (tab) {
  ToolTab.quick => t.serial.tab.quick,
  ToolTab.batch => t.serial.tab.batch,
  ToolTab.reply => t.serial.tab.reply,
  ToolTab.history => t.serial.tab.history,
  ToolTab.calc => t.serial.tab.calc,
  ToolTab.script => t.serial.tab.script,
};

class _Bar extends StatelessWidget {
  const _Bar({
    required this.note,
    required this.actions,
    this.leading,
    this.expand,
  });

  final String note;
  final List<Widget> actions;
  final Widget? leading;

  /// 占满 note 槽位的部件（如批量页的任务下拉）；提供时不显示 note。
  final Widget? expand;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final expand = this.expand;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line2)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          if (expand != null)
            Expanded(child: expand)
          else
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

class _QuickTab extends StatelessWidget {
  const _QuickTab({required this.state});

  final SerialConsoleState state;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final q = t.serial.quick;
    final cubit = context.read<SerialConsoleCubit>();

    Widget command(QuickCommand item, {bool indent = false}) => _ItemRow(
      indent: indent,
      leading: SerialButton(
        label: q.send,
        small: true,
        primary: true,
        onPressed: () => cubit.sendQuick(item.id),
      ),
      title: item.name,
      detail: item.format == DataFormat.ascii
          ? '${t.serial.mark.ascii} · ${item.data}'
          : item.data,
      trailing: [if (item.key.isNotEmpty) _KeyChip(item.key)],
      menu: [
        SerialMenuAction(
          label: t.common.edit,
          onTap: () => showQuickEditor(context, existing: item),
        ),
        SerialMenuAction(
          label: t.common.duplicate,
          onTap: () => cubit.duplicateQuick(item.id),
        ),
        SerialMenuAction(
          label: t.common.delete,
          danger: true,
          onTap: () => showSerialDelete(
            context,
            message: t.serial.dialog.deleteQuick(name: item.name),
            onDelete: () => cubit.deleteQuick(item.id),
          ),
        ),
      ],
    );

    return Column(
      children: [
        _Bar(
          note: q.note,
          actions: [
            SerialButton(
              label: q.newFolder,
              small: true,
              onPressed: () => showFolderEditor(context),
            ),
            SerialButton(
              label: t.common.add,
              small: true,
              onPressed: () => showQuickEditor(context),
            ),
          ],
        ),
        Expanded(
          child: state.quick.isEmpty
              ? _Explain(q.empty)
              : ListView(
                  children: [
                    for (final node in state.quick)
                      ...switch (node) {
                        QuickCommand() => [command(node)],
                        QuickFolder() => [
                          _FolderRow(folder: node),
                          if (node.expanded) ...[
                            for (final item in node.commands)
                              command(item, indent: true),
                            if (node.commands.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.lg,
                                ),
                                child: _Explain(q.folderEmpty),
                              ),
                          ],
                        ],
                      },
                  ],
                ),
        ),
      ],
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({required this.folder});

  final QuickFolder folder;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final q = t.serial.quick;
    final cubit = context.read<SerialConsoleCubit>();
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final count = folder.commands.length;
    return SerialContextMenu(
      menu: [
        SerialMenuAction(
          label: q.rename,
          onTap: () => showFolderEditor(context, existing: folder),
        ),
        SerialMenuAction(
          label: t.common.delete,
          danger: true,
          onTap: () => showSerialDelete(
            context,
            message: count == 0
                ? t.serial.dialog.deleteFolder(name: folder.name)
                : t.serial.dialog.deleteFolderWith(
                    name: folder.name,
                    count: count,
                  ),
            onDelete: () => cubit.deleteFolder(folder.id),
          ),
        ),
      ],
      child: HoverSurface(
        onTap: () => cubit.toggleFolder(folder.id),
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
              Icon(
                folder.expanded ? Icons.expand_more : Icons.chevron_right,
                size: 18,
                color: palette.muted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    cs,
                  ).copyWith(color: palette.text, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                q.folderCount(count: count),
                style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
              ),
              const SizedBox(width: AppSpacing.sm),
              SerialLinkButton(
                label: q.add,
                onPressed: () => showQuickEditor(context, folderId: folder.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchTab extends StatelessWidget {
  const _BatchTab({required this.state});

  final SerialConsoleState state;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cubit = context.read<SerialConsoleCubit>();
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    if (state.batch.isEmpty) {
      return Column(
        children: [
          _Bar(
            note: '',
            actions: [
              SerialButton(
                label: t.serial.batch.kNew,
                small: true,
                onPressed: () => showBatchEditor(context),
              ),
            ],
          ),
          _Explain(t.serial.batch.empty),
        ],
      );
    }
    var selected = state.batch.first;
    for (final job in state.batch) {
      if (job.id == state.selectedBatchId) selected = job;
    }
    final run = state.batchRun?.jobId == selected.id ? state.batchRun : null;
    // 顶栏已有「编辑」，右键菜单只补复制和删除
    final jobMenu = [
      SerialMenuAction(
        label: t.common.duplicate,
        onTap: () => cubit.duplicateBatch(selected.id),
      ),
      SerialMenuAction(
        label: t.common.delete,
        danger: true,
        onTap: () => showSerialDelete(
          context,
          message: t.serial.dialog.deleteBatch(name: selected.name),
          onDelete: () => cubit.deleteBatch(selected.id),
        ),
      ),
    ];
    return Column(
      children: [
        SerialContextMenu(
          menu: jobMenu,
          child: _Bar(
            note: '',
            expand: SerialDropdown<String>(
              value: selected.id,
              items: [
                for (final job in state.batch) (value: job.id, label: job.name),
              ],
              onChanged: cubit.selectBatch,
            ),
            actions: [
              SerialButton(
                label: t.serial.batch.kNew,
                small: true,
                onPressed: () => showBatchEditor(context),
              ),
              SerialButton(
                label: t.serial.batch.edit,
                small: true,
                onPressed: () => showBatchEditor(context, existing: selected),
              ),
              SerialButton(
                label: t.serial.batch.delete,
                small: true,
                danger: true,
                onPressed: () => showSerialDelete(
                  context,
                  message: t.serial.dialog.deleteBatch(name: selected.name),
                  onDelete: () => cubit.deleteBatch(selected.id),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.sm,
          ),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.serial.batch.repeat,
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted, fontSize: 13),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  _RepeatBox(
                    value: selected.repeat,
                    onCommit: (value) =>
                        cubit.setBatchRepeat(selected.id, value),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    t.serial.batch.rounds,
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted, fontSize: 13),
                  ),
                ],
              ),
              SerialCheck(
                label: t.serial.batch.stopOnFail,
                value: selected.stopOnFail,
                onChanged: (value) =>
                    cubit.setBatchStopOnFail(selected.id, value),
              ),
              Text(
                run == null
                    ? t.serial.batch.commands(count: selected.steps.length)
                    : t.serial.batch.progress(
                        round: run.round,
                        rounds: run.rounds,
                        step: run.step,
                        total: run.total,
                      ),
                style: AppTextStyles.caption(
                  cs,
                ).copyWith(color: palette.muted, fontSize: 13),
              ),
              if (run == null)
                SerialButton(
                  label: t.serial.batch.start,
                  small: true,
                  primary: true,
                  onPressed: () => cubit.runBatch(selected.id),
                )
              else
                SerialButton(
                  label: t.serial.batch.stop,
                  small: true,
                  danger: true,
                  onPressed: cubit.stopBatch,
                ),
            ],
          ),
        ),
        if (run != null)
          LinearProgressIndicator(
            minHeight: 3,
            value: (run.rounds * run.total) == 0
                ? 0
                : ((run.round - 1) * run.total + run.step) /
                      (run.rounds * run.total),
            color: palette.accent,
            backgroundColor: palette.line2,
          ),
        Expanded(
          child: SerialContextMenu(
            menu: jobMenu,
            child: ListView(
              children: [
                _TableHead(t),
                for (var i = 0; i < selected.steps.length; i++)
                  _StepLine(
                    index: i + 1,
                    step: selected.steps[i],
                    active: run != null && run.step == i + 1,
                  ),
                _Explain(t.serial.batch.explain),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplyTab extends StatelessWidget {
  const _ReplyTab({required this.state});

  final SerialConsoleState state;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cubit = context.read<SerialConsoleCubit>();
    final enabled = state.rules.where((rule) => rule.enabled).length;
    return Column(
      children: [
        _Bar(
          note: t.serial.reply.note(
            enabled: enabled,
            total: state.rules.length,
          ),
          actions: [
            SerialButton(
              label: t.serial.reply.add,
              small: true,
              onPressed: () => showRuleEditor(context),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            children: [
              for (final rule in state.rules)
                _ItemRow(
                  leading: SerialSwitch(
                    on: rule.enabled,
                    onTap: () => cubit.toggleRule(rule.id),
                  ),
                  title: rule.name,
                  detail:
                      '${ruleMatchLabel(t, rule)} → ${rule.replies.map((reply) => '+${reply.delayMs}ms ${reply.data}').join('，')}',
                  trailing: [
                    Text(
                      t.serial.reply.hits(count: rule.hits),
                      style: AppTextStyles.mono(
                        Theme.of(context).colorScheme,
                        fontSize: 12,
                        color: SerialPalette.of(context).muted,
                      ),
                    ),
                    SerialLinkButton(
                      label: t.serial.reply.fire,
                      onPressed: () => cubit.fireRule(rule.id),
                    ),
                  ],
                  menu: [
                    SerialMenuAction(
                      label: t.common.edit,
                      onTap: () => showRuleEditor(context, existing: rule),
                    ),
                    SerialMenuAction(
                      label: t.common.duplicate,
                      onTap: () => cubit.duplicateRule(rule.id),
                    ),
                    SerialMenuAction(
                      label: t.common.delete,
                      danger: true,
                      onTap: () => showSerialDelete(
                        context,
                        message: t.serial.dialog.deleteRule(name: rule.name),
                        onDelete: () => cubit.deleteRule(rule.id),
                      ),
                    ),
                  ],
                ),
              _Explain(t.serial.reply.explain),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.state});

  final SerialConsoleState state;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cubit = context.read<SerialConsoleCubit>();
    return Column(
      children: [
        _Bar(
          note: t.serial.history.note,
          actions: [
            SerialButton(
              label: t.serial.history.clear,
              small: true,
              onPressed: state.history.isEmpty
                  ? null
                  : () => showSerialDelete(
                      context,
                      message: t.serial.dialog.deleteHistory(
                        count: state.history.length,
                      ),
                      onDelete: cubit.clearHistory,
                    ),
            ),
          ],
        ),
        Expanded(
          child: state.history.isEmpty
              ? _Explain(t.serial.history.empty)
              : ListView(
                  children: [
                    for (var i = 0; i < state.history.length; i++)
                      _ItemRow(
                        leading: SerialButton(
                          label: state.history[i].time == null
                              ? t.serial.history.beforeStart
                              : clockStamp(
                                  state.history[i].time!,
                                ).substring(0, 8),
                          small: true,
                          onPressed: () => cubit.resendHistory(i),
                        ),
                        title: state.history[i].text,
                        monoTitle: true,
                        detail: t.serial.history.fillHint,
                        trailing: [
                          SerialLinkButton(
                            label: t.serial.history.fill,
                            onPressed: () => cubit.fillHistory(i),
                          ),
                          SerialLinkButton(
                            label: t.common.delete,
                            danger: true,
                            onPressed: () => cubit.removeHistory(i),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ScriptTab extends StatelessWidget {
  const _ScriptTab({required this.state});

  final SerialConsoleState state;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final s = t.serial.script;
    final cubit = context.read<SerialConsoleCubit>();
    final enabled = state.scripts.where((item) => item.enabled).length;
    final current = state.scriptDockVisible ? state.selectedScript : null;
    final note = s.note(enabled: enabled, total: state.scripts.length);
    final views = _ScriptViewSwitch(
      tutorial: state.scriptTutorial,
      mineLabel: s.mine(count: state.scripts.length),
      tutorialLabel: s.tutorial,
      onChanged: cubit.setScriptTutorial,
    );
    if (state.scriptTutorial) {
      return Column(
        children: [
          _Bar(leading: views, note: note, actions: const []),
          Expanded(
            child: ListView(
              children: [
                for (final (i, lesson) in ScriptLesson.all.indexed)
                  _LessonRow(
                    index: i + 1,
                    lesson: lesson,
                    open: state.openLesson == lesson.key,
                  ),
                _Explain(s.tutorialNote),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _Bar(
          leading: views,
          note: note,
          actions: [
            SerialButton(label: s.add, small: true, onPressed: cubit.newScript),
          ],
        ),
        Expanded(
          child: ListView(
            children: [
              for (final script in state.scripts)
                _ScriptRow(
                  script: script,
                  meta: state.scriptMeta[script.id] ?? const ScriptMeta(),
                  active: script.id == current?.id,
                ),
              if (state.scripts.isEmpty) _Explain(s.empty),
              _Explain(s.explain),
            ],
          ),
        ),
      ],
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
  final ScriptMeta meta;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final s = t.serial.script;
    final cubit = context.read<SerialConsoleCubit>();
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final status = meta.outputs > 0
        ? s.outputs(count: meta.outputs)
        : (script.enabled ? s.waiting : s.off);
    return SerialContextMenu(
      menu: [
        SerialMenuAction(
          label: s.rename,
          onTap: () => showScriptRename(context, script),
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
            message: t.serial.dialog.deleteScript(name: script.name),
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
              Tooltip(
                message: s.toggle,
                child: SerialSwitch(
                  on: script.enabled,
                  onTap: () => cubit.toggleScript(script.id),
                ),
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
                        ...scriptHookChips(context, meta),
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

/// 脚本页顶部「我的脚本 / 教程」分段切换。
class _ScriptViewSwitch extends StatelessWidget {
  const _ScriptViewSwitch({
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

/// 课表一行；展开后显示说明、代码、样例帧与操作。
class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.open,
  });

  final int index;
  final ScriptLesson lesson;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final s = t.serial.script;
    final text = lessonText(t, lesson.key);
    final cubit = context.read<SerialConsoleCubit>();
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final mono = AppTextStyles.mono(cs, fontSize: 12, color: palette.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HoverSurface(
          color: open ? palette.accent.withValues(alpha: 0.14) : null,
          onTap: () => cubit.toggleLesson(lesson.key),
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
                SizedBox(
                  width: 18,
                  child: Text(
                    '$index',
                    textAlign: TextAlign.right,
                    style: mono.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(cs).copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          scriptHookChip(lesson.hook),
                          Expanded(
                            child: Text(
                              text.brief,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(
                                cs,
                              ).copyWith(color: palette.muted),
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
        if (open)
          Container(
            padding: const EdgeInsets.fromLTRB(
              38,
              AppSpacing.sm + 2,
              AppSpacing.sm + 2,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.line2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  text.text,
                  style: AppTextStyles.body(
                    cs,
                  ).copyWith(fontSize: 13, height: 1.6, color: palette.text),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: palette.logBg,
                    border: Border.all(color: palette.line2),
                    borderRadius: BorderRadius.circular(
                      SerialMetrics.controlRadius,
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      lesson.code.trimRight(),
                      style: AppTextStyles.mono(
                        cs,
                        fontSize: 12,
                        height: 1.55,
                        color: palette.logRx,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(s.lessonSample(hex: lesson.sample), style: mono),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    SerialButton(
                      label: s.lessonNew,
                      small: true,
                      primary: true,
                      onPressed: () => cubit.newScriptFromLesson(lesson),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
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
      ],
    );
  }
}

class _CalcTab extends StatelessWidget {
  const _CalcTab({
    required this.format,
    required this.controller,
    required this.onFormat,
    required this.onUseTx,
    required this.onEdited,
  });

  final DataFormat format;
  final TextEditingController controller;
  final ValueChanged<DataFormat> onFormat;
  final VoidCallback onUseTx;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final bytes = format == DataFormat.hex
        ? SerialBytes.parseHex(controller.text)
        : SerialBytes.textBytes(controller.text, escape: true);
    final algos = [
      (ChecksumKind.sum, t.serial.calc.sum),
      (ChecksumKind.xor, t.serial.calc.xor),
      (ChecksumKind.lrc, t.serial.calc.lrc),
      (ChecksumKind.crc8, t.serial.calc.crc8),
      (ChecksumKind.crc16, t.serial.calc.crc16),
      (ChecksumKind.crc32, t.serial.calc.crc32),
    ];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      children: [
        Row(
          children: [
            _MiniRadio(
              label: t.serial.mark.hex,
              selected: format == DataFormat.hex,
              onTap: () => onFormat(DataFormat.hex),
            ),
            const SizedBox(width: AppSpacing.md),
            _MiniRadio(
              label: t.serial.mark.ascii,
              selected: format == DataFormat.ascii,
              onTap: () => onFormat(DataFormat.ascii),
            ),
            const Spacer(),
            SerialLinkButton(label: t.serial.calc.fromTx, onPressed: onUseTx),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          onChanged: (_) => onEdited(),
          style: AppTextStyles.mono(cs, fontSize: 14, color: palette.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.field,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
              borderSide: BorderSide(color: palette.line),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (bytes == null || bytes.isEmpty)
          Text(
            format == DataFormat.hex
                ? t.serial.calc.badHex
                : t.serial.calc.empty,
            style: AppTextStyles.caption(cs).copyWith(color: palette.off),
          )
        else ...[
          _CalcRow(t.serial.calc.bytes, '${bytes.length}', null),
          for (final algo in algos)
            _CalcRow(
              algo.$2,
              SerialBytes.toHex(SerialBytes.checksumBytes(bytes, algo.$1)),
              () {
                context.read<SerialConsoleCubit>().appendChecksum(
                  Uint8List.fromList(bytes),
                  algo.$1,
                );
              },
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          t.serial.calc.explain,
          style: AppTextStyles.caption(
            cs,
          ).copyWith(color: palette.muted, height: 1.6),
        ),
      ],
    );
  }
}

class _CalcRow extends StatelessWidget {
  const _CalcRow(this.label, this.value, this.onAppend);

  final String label;
  final String value;
  final VoidCallback? onAppend;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 3),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(
                cs,
              ).copyWith(color: palette.text, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.mono(
              cs,
              fontSize: 14,
              color: palette.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onAppend != null)
            SerialLinkButton(
              label: Translations.of(context).serial.calc.append,
              onPressed: onAppend,
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.leading,
    required this.title,
    required this.detail,
    required this.trailing,
    this.monoTitle = false,
    this.indent = false,
    this.menu,
  });

  final Widget leading;
  final String title;
  final String detail;
  final List<Widget> trailing;
  final bool monoTitle;
  final bool indent;

  /// 行上只留主操作时，其余操作从这里右键弹出。
  final List<SerialMenuAction>? menu;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final menu = this.menu;
    final row = HoverSurface(
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
            leading,
            const SizedBox(width: AppSpacing.sm + 2),
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

class _KeyChip extends StatelessWidget {
  const _KeyChip(this.label);

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

class _Explain extends StatelessWidget {
  const _Explain(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Text(
        text,
        style: AppTextStyles.caption(
          Theme.of(context).colorScheme,
        ).copyWith(color: palette.muted, height: 1.6),
      ),
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead(this.t);

  final Translations t;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final style = AppTextStyles.caption(
      Theme.of(context).colorScheme,
    ).copyWith(color: palette.muted, fontWeight: FontWeight.w600);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(t.serial.batch.colIndex, style: style),
          ),
          SizedBox(
            width: 72,
            child: Text(t.serial.batch.colDelay, style: style),
          ),
          Expanded(child: Text(t.serial.batch.colData, style: style)),
          SizedBox(
            width: 88,
            child: Text(t.serial.batch.colNote, style: style),
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({
    required this.index,
    required this.step,
    required this.active,
  });

  final int index;
  final BatchStep step;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final style = AppTextStyles.mono(cs, fontSize: 13, color: palette.text);
    return Container(
      color: active
          ? palette.accent.withValues(alpha: 0.16)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$index', style: style)),
          SizedBox(width: 72, child: Text('${step.delayMs} ms', style: style)),
          Expanded(
            child: Text(
              step.data,
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 88,
            child: Text(
              step.note,
              style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepeatBox extends StatefulWidget {
  const _RepeatBox({required this.value, required this.onCommit});

  final int value;
  final ValueChanged<int> onCommit;

  @override
  State<_RepeatBox> createState() => _RepeatBoxState();
}

class _RepeatBoxState extends State<_RepeatBox> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.value}',
  );

  @override
  void didUpdateWidget(covariant _RepeatBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = '${widget.value}';
    if (_controller.text != text) _controller.text = text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: SerialField(
        controller: _controller,
        height: SerialMetrics.buttonSm,
        onSubmitted: (value) => widget.onCommit(int.tryParse(value) ?? 0),
        onFocusLost: () => widget.onCommit(int.tryParse(_controller.text) ?? 0),
      ),
    );
  }
}

class _MiniRadio extends StatelessWidget {
  const _MiniRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: RadioGroup<bool>(
              groupValue: selected,
              onChanged: (_) => onTap(),
              child: const Radio<bool>(value: true),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      ),
    );
  }
}
