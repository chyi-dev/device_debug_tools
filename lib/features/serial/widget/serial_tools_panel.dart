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
import '../../mcp/widget/mcp_log_panel.dart';
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
                child: SerialTabScroller(
                  children: [
                    for (final tab in ToolTab.values)
                      _tabButton(context, state, tab),
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
    ToolTab tab,
  ) {
    final palette = SerialPalette.of(context);
    final active = state.tab == tab;
    return InkWell(
      onTap: () => context.read<SerialConsoleCubit>().setTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
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
      ToolTab.mcp => const McpLogPanel(),
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
  ToolTab.mcp => t.mcp.tab,
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

    Widget command(QuickCommand item, {bool indent = false}) {
      final row = _ItemRow(
        indent: indent,
        leading: SerialSwitch(
          on: item.enabled,
          onTap: () => cubit.toggleQuick(item.id),
        ),
        title: item.name,
        detail: item.format == DataFormat.ascii
            ? '${t.serial.mark.ascii} · ${item.data}'
            : item.data,
        trailing: [
          SerialButton(
            label: q.send,
            small: true,
            primary: true,
            onPressed: item.enabled ? () => cubit.sendQuick(item.id) : null,
          ),
          if (item.key.isNotEmpty) _KeyChip(item.key),
        ],
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
      return _QuickCommandDrag(command: item, child: row);
    }

    final bar = _Bar(
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
    );

    if (state.quick.isEmpty) {
      return Column(
        children: [
          bar,
          Expanded(child: _Explain(q.empty)),
        ],
      );
    }

    return Column(
      children: [
        _QuickRootDrop(child: bar),
        Expanded(
          child: ListView(
            children: [
              for (final node in state.quick)
                ...switch (node) {
                  QuickCommand() => [
                    _QuickBeforeDrop(
                      beforeId: node.id,
                      allowFolder: true,
                      child: command(node),
                    ),
                  ],
                  QuickFolder() => [
                    // 标题：指令→移入夹；文件夹→插到此夹之前。夹内指令仅接受指令排序。
                    _QuickFolderDrop(
                      folder: node,
                      child: _QuickFolderDrag(
                        folder: node,
                        child: _FolderRow(folder: node),
                      ),
                    ),
                    if (node.expanded) ...[
                      for (final item in node.commands)
                        _QuickBeforeDrop(
                          beforeId: item.id,
                          child: command(item, indent: true),
                        ),
                      if (node.commands.isEmpty)
                        _QuickFolderDrop(
                          folder: node,
                          commandsOnly: true,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.lg,
                            ),
                            child: _Explain(q.folderEmpty),
                          ),
                        ),
                    ],
                  ],
                },
              _QuickRootDrop(child: const SizedBox(height: AppSpacing.lg)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickRootDrop extends StatelessWidget {
  const _QuickRootDrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SerialConsoleCubit>();
    final q = Translations.of(context).serial.quick;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final id = details.data;
        final quick = cubit.state.quick;
        if (quick.folderById(id) != null) {
          return !(quick.isNotEmpty && quick.last.id == id);
        }
        final command = quick.commandById(id);
        if (command == null) return false;
        if (quick.folderIdOf(command.id) == null &&
            quick.isNotEmpty &&
            quick.last.id == command.id) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        final id = details.data;
        if (cubit.state.quick.folderById(id) != null) {
          cubit.placeQuick(id);
        } else {
          cubit.moveQuick(id);
        }
      },
      builder: (context, candidate, rejected) {
        final hot = candidate.isNotEmpty;
        return _QuickDropHighlight(
          hot: hot,
          label: q.dropRoot,
          child: child,
        );
      },
    );
  }
}

/// 拖到某条指令上：插到该条之前。[allowFolder] 为真时根级指令也可接文件夹。
class _QuickBeforeDrop extends StatelessWidget {
  const _QuickBeforeDrop({
    required this.beforeId,
    required this.child,
    this.allowFolder = false,
  });

  final String beforeId;
  final Widget child;
  final bool allowFolder;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SerialConsoleCubit>();
    final q = Translations.of(context).serial.quick;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final id = details.data;
        if (id == beforeId) return false;
        if (cubit.state.quick.commandById(id) != null) return true;
        return allowFolder && cubit.state.quick.folderById(id) != null;
      },
      onAcceptWithDetails: (details) =>
          cubit.placeQuick(details.data, beforeId: beforeId),
      builder: (context, candidate, rejected) {
        final hot = candidate.isNotEmpty;
        return _QuickDropHighlight(
          hot: hot,
          label: q.dropBefore,
          child: child,
        );
      },
    );
  }
}

class _QuickDropHighlight extends StatelessWidget {
  const _QuickDropHighlight({
    required this.hot,
    required this.label,
    required this.child,
  });

  final bool hot;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hot ? palette.accent.withValues(alpha: 0.12) : null,
        border: hot ? Border.all(color: palette.accent) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hot)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm + 2,
                top: AppSpacing.xs,
              ),
              child: Text(
                label,
                style: AppTextStyles.caption(
                  Theme.of(context).colorScheme,
                ).copyWith(color: palette.accent),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _QuickCommandDrag extends StatelessWidget {
  const _QuickCommandDrag({required this.command, required this.child});

  final QuickCommand command;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Draggable<String>(
      data: command.id,
      feedback: Material(
        elevation: 3,
        color: palette.panel,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              command.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(cs).copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: child,
    );
  }
}

class _QuickFolderDrag extends StatelessWidget {
  const _QuickFolderDrag({required this.folder, required this.child});

  final QuickFolder folder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Draggable<String>(
      data: folder.id,
      feedback: Material(
        elevation: 3,
        color: palette.panel,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(cs).copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: child,
    );
  }
}

class _QuickFolderDrop extends StatelessWidget {
  const _QuickFolderDrop({
    required this.folder,
    required this.child,
    this.commandsOnly = false,
  });

  final QuickFolder folder;
  final Widget child;

  /// 空夹提示区只收指令，不收文件夹。
  final bool commandsOnly;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SerialConsoleCubit>();
    final q = Translations.of(context).serial.quick;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final id = details.data;
        final quick = cubit.state.quick;
        if (quick.folderById(id) != null) {
          if (commandsOnly || id == folder.id) return false;
          return true;
        }
        final command = quick.commandById(id);
        if (command == null) return false;
        if (quick.folderIdOf(command.id) == folder.id) {
          final list = folder.commands;
          if (list.isNotEmpty && list.last.id == command.id) return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        final id = details.data;
        if (cubit.state.quick.folderById(id) != null) {
          cubit.placeQuick(id, beforeId: folder.id);
        } else {
          cubit.moveQuick(id, folderId: folder.id);
        }
      },
      builder: (context, candidate, rejected) {
        final hot = candidate.isNotEmpty;
        final draggingId = candidate.whereType<String>().firstOrNull;
        final draggingFolder =
            draggingId != null &&
            cubit.state.quick.folderById(draggingId) != null;
        return _QuickDropHighlight(
          hot: hot,
          label: draggingFolder ? q.dropBefore : q.dropFolder,
          child: child,
        );
      },
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
    final r = t.serial.reply;
    final cubit = context.read<SerialConsoleCubit>();
    final palette = SerialPalette.of(context);
    final enabled = state.rules.allRules.where((rule) => rule.enabled).length;
    final total = state.rules.allRules.length;

    Widget ruleRow(ReplyRule rule, {bool indent = false}) {
      final row = _ItemRow(
        indent: indent,
        leading: SerialSwitch(
          on: rule.enabled,
          onTap: () => cubit.toggleRule(rule.id),
        ),
        title: rule.name,
        detail:
            '${ruleMatchLabel(t, rule)} → ${rule.replies.map((reply) => '+${reply.delayMs}ms ${reply.data}').join('，')}',
        trailing: [
          Text(
            r.hits(count: rule.hits),
            style: AppTextStyles.mono(
              Theme.of(context).colorScheme,
              fontSize: 12,
              color: palette.muted,
            ),
          ),
          SerialLinkButton(
            label: r.fire,
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
      );
      return _ReplyRuleDrag(rule: rule, child: row);
    }

    return Column(
      children: [
        _ReplyRootDrop(
          child: _Bar(
            note: r.note(enabled: enabled, total: total),
            actions: [
              SerialButton(
                label: r.newFolder,
                small: true,
                onPressed: () => showReplyFolderEditor(context),
              ),
              SerialButton(
                label: r.add,
                small: true,
                onPressed: () => showRuleEditor(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final node in state.rules)
                ...switch (node) {
                  ReplyRule() => [
                    _ReplyBeforeDrop(
                      beforeId: node.id,
                      allowFolder: true,
                      child: ruleRow(node),
                    ),
                  ],
                  ReplyFolder() => [
                    // 标题：规则→移入夹；文件夹→插到此夹之前。夹内规则仅接受规则排序。
                    _ReplyFolderDrop(
                      folder: node,
                      child: _ReplyFolderDrag(
                        folder: node,
                        child: _ReplyFolderRow(folder: node),
                      ),
                    ),
                    if (node.expanded) ...[
                      for (final rule in node.rules)
                        _ReplyBeforeDrop(
                          beforeId: rule.id,
                          child: ruleRow(rule, indent: true),
                        ),
                      if (node.rules.isEmpty)
                        _ReplyFolderDrop(
                          folder: node,
                          rulesOnly: true,
                          child: Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.lg),
                            child: _Explain(r.folderEmpty),
                          ),
                        ),
                    ],
                  ],
                },
              _ReplyRootDrop(child: _Explain(r.explain)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReplyRootDrop extends StatelessWidget {
  const _ReplyRootDrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SerialConsoleCubit>();
    final r = Translations.of(context).serial.reply;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final id = details.data;
        final rules = cubit.state.rules;
        if (rules.folderById(id) != null) {
          return !(rules.isNotEmpty && rules.last.id == id);
        }
        final rule = rules.ruleById(id);
        if (rule == null) return false;
        if (rules.folderIdOf(rule.id) == null &&
            rules.isNotEmpty &&
            rules.last.id == rule.id) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        final id = details.data;
        if (cubit.state.rules.folderById(id) != null) {
          cubit.placeRule(id);
        } else {
          cubit.moveRule(id);
        }
      },
      builder: (context, candidate, rejected) {
        final hot = candidate.isNotEmpty;
        return _ReplyDropHighlight(
          hot: hot,
          label: r.dropRoot,
          child: child,
        );
      },
    );
  }
}

/// 拖到某条规则上：插到该条之前。[allowFolder] 为真时根级规则也可接文件夹。
class _ReplyBeforeDrop extends StatelessWidget {
  const _ReplyBeforeDrop({
    required this.beforeId,
    required this.child,
    this.allowFolder = false,
  });

  final String beforeId;
  final Widget child;
  final bool allowFolder;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SerialConsoleCubit>();
    final r = Translations.of(context).serial.reply;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final id = details.data;
        if (id == beforeId) return false;
        if (cubit.state.rules.ruleById(id) != null) return true;
        return allowFolder && cubit.state.rules.folderById(id) != null;
      },
      onAcceptWithDetails: (details) =>
          cubit.placeRule(details.data, beforeId: beforeId),
      builder: (context, candidate, rejected) {
        final hot = candidate.isNotEmpty;
        return _ReplyDropHighlight(
          hot: hot,
          label: r.dropBefore,
          child: child,
        );
      },
    );
  }
}

class _ReplyDropHighlight extends StatelessWidget {
  const _ReplyDropHighlight({
    required this.hot,
    required this.label,
    required this.child,
  });

  final bool hot;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hot ? palette.accent.withValues(alpha: 0.12) : null,
        border: hot ? Border.all(color: palette.accent) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hot)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm + 2,
                top: AppSpacing.xs,
              ),
              child: Text(
                label,
                style: AppTextStyles.caption(
                  Theme.of(context).colorScheme,
                ).copyWith(color: palette.accent),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _ReplyRuleDrag extends StatelessWidget {
  const _ReplyRuleDrag({required this.rule, required this.child});

  final ReplyRule rule;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Draggable<String>(
      data: rule.id,
      feedback: Material(
        elevation: 3,
        color: palette.panel,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              rule.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(cs).copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: child,
    );
  }
}

class _ReplyFolderDrag extends StatelessWidget {
  const _ReplyFolderDrag({required this.folder, required this.child});

  final ReplyFolder folder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Draggable<String>(
      data: folder.id,
      feedback: Material(
        elevation: 3,
        color: palette.panel,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(cs).copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: child,
    );
  }
}

class _ReplyFolderDrop extends StatelessWidget {
  const _ReplyFolderDrop({
    required this.folder,
    required this.child,
    this.rulesOnly = false,
  });

  final ReplyFolder folder;
  final Widget child;

  /// 空夹提示区只收规则，不收文件夹。
  final bool rulesOnly;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SerialConsoleCubit>();
    final r = Translations.of(context).serial.reply;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final id = details.data;
        final rules = cubit.state.rules;
        if (rules.folderById(id) != null) {
          if (rulesOnly || id == folder.id) return false;
          return true;
        }
        final rule = rules.ruleById(id);
        if (rule == null) return false;
        if (rules.folderIdOf(rule.id) == folder.id) {
          final list = folder.rules;
          if (list.isNotEmpty && list.last.id == rule.id) return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        final id = details.data;
        if (cubit.state.rules.folderById(id) != null) {
          cubit.placeRule(id, beforeId: folder.id);
        } else {
          cubit.moveRule(id, folderId: folder.id);
        }
      },
      builder: (context, candidate, rejected) {
        final hot = candidate.isNotEmpty;
        final draggingId = candidate.whereType<String>().firstOrNull;
        final draggingFolder =
            draggingId != null &&
            cubit.state.rules.folderById(draggingId) != null;
        return _ReplyDropHighlight(
          hot: hot,
          label: draggingFolder ? r.dropBefore : r.dropFolder,
          child: child,
        );
      },
    );
  }
}

class _ReplyFolderRow extends StatelessWidget {
  const _ReplyFolderRow({required this.folder});

  final ReplyFolder folder;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final r = t.serial.reply;
    final cubit = context.read<SerialConsoleCubit>();
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final count = folder.rules.length;
    return SerialContextMenu(
      menu: [
        SerialMenuAction(
          label: r.rename,
          onTap: () => showReplyFolderEditor(context, existing: folder),
        ),
        SerialMenuAction(
          label: t.common.delete,
          danger: true,
          onTap: () => showSerialDelete(
            context,
            message: count == 0
                ? t.serial.dialog.deleteFolder(name: folder.name)
                : t.serial.dialog.deleteReplyFolderWith(
                    name: folder.name,
                    count: count,
                  ),
            onDelete: () => cubit.deleteReplyFolder(folder.id),
          ),
        ),
      ],
      child: HoverSurface(
        onTap: () => cubit.toggleReplyFolder(folder.id),
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
                r.folderCount(count: count),
                style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
              ),
              const SizedBox(width: AppSpacing.sm),
              SerialLinkButton(
                label: r.add,
                onPressed: () =>
                    showRuleEditor(context, folderId: folder.id),
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Color.lerp(palette.field, palette.accent, 0.08),
        border: Border.all(
          color: Color.lerp(palette.line, palette.accent, 0.35)!,
        ),
        borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
      ),
      child: Text(
        label,
        style: AppTextStyles.mono(
          Theme.of(context).colorScheme,
          fontSize: 12,
          color: palette.accent,
        ).copyWith(fontWeight: FontWeight.w600, height: 1),
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
