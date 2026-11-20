import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../mcp/widget/mcp_log_panel.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_editors.dart';
import '../cubit/ble_console_cubit.dart';
import '../cubit/ble_console_state.dart';
import '../model/ble_models.dart';
import 'ble_editors.dart';

class BleToolsPanel extends StatelessWidget {
  const BleToolsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      buildWhen: (a, b) => a.tab != b.tab,
      builder: (context, state) {
        final cubit = context.read<BleConsoleCubit>();
        final tabs = kBleToolTabs;
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
                    for (final tab in tabs)
                      _tabButton(
                        context,
                        label: _label(t, tab),
                        active: state.tab == tab,
                        onTap: () => cubit.setTab(tab),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: palette.line),
              Expanded(
                child: switch (bleToolTab(state.tab)) {
                  ToolTab.quick => const _QuickTab(),
                  ToolTab.batch => const _BatchTab(),
                  ToolTab.reply => const _ReplyTab(),
                  ToolTab.history => const _HistoryTab(),
                  ToolTab.script => const _ScriptTab(),
                  ToolTab.mcp => const McpLogPanel(),
                  ToolTab.calc => const _QuickTab(),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

String _label(Translations t, ToolTab tab) => switch (tab) {
  ToolTab.quick => t.serial.tab.quick,
  ToolTab.batch => t.serial.tab.batch,
  ToolTab.reply => t.serial.tab.reply,
  ToolTab.history => t.serial.tab.history,
  ToolTab.script => t.serial.tab.script,
  ToolTab.mcp => t.mcp.tab,
  ToolTab.calc => t.serial.tab.quick,
};

Widget _tabButton(
  BuildContext context, {
  required String label,
  required bool active,
  required VoidCallback onTap,
}) {
  final palette = SerialPalette.of(context);
  return InkWell(
    onTap: onTap,
    child: AnimatedContainer(
      duration: SerialMetrics.motion,
      curve: SerialMetrics.motionCurve,
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
        label,
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

class _QuickTab extends StatelessWidget {
  const _QuickTab();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      buildWhen: (a, b) => a.quick != b.quick || a.pinWrite != b.pinWrite,
      builder: (context, state) {
        final cubit = context.read<BleConsoleCubit>();
        return Column(
          children: [
            SerialToolBar(
              note: state.pinWrite == null
                  ? t.ble.quick.targetNone
                  : t.ble.quick.target(uuid: state.pinWrite!.uuid),
              actions: [
                SerialButton(
                  label: t.common.add,
                  small: true,
                  onPressed: () async {
                    final item = await showBleQuickEditor(context);
                    if (item != null) cubit.saveQuick(item);
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final item in state.quick)
                    SerialItemRow(
                      leading: SerialSwitch(
                        on: item.enabled,
                        onTap: () => cubit.toggleQuick(item.id),
                      ),
                      title: item.name,
                      detail: item.data,
                      trailing: [
                        SerialButton(
                          label: t.ble.send,
                          small: true,
                          primary: true,
                          onPressed: item.enabled
                              ? () => cubit.sendQuick(item.id)
                              : null,
                        ),
                        if (item.key.isNotEmpty) SerialKeyChip(item.key),
                      ],
                      menu: [
                        SerialMenuAction(
                          label: t.common.edit,
                          onTap: () async {
                            final next = await showBleQuickEditor(
                              context,
                              initial: item,
                            );
                            if (next != null) cubit.saveQuick(next);
                          },
                        ),
                        SerialMenuAction(
                          label: t.common.delete,
                          danger: true,
                          onTap: () => showSerialDelete(
                            context,
                            message: t.ble.dialog.deleteQuick,
                            onDelete: () => cubit.deleteQuick(item.id),
                          ),
                        ),
                      ],
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

class _BatchTab extends StatelessWidget {
  const _BatchTab();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      buildWhen: (a, b) => a.batch != b.batch || a.batchRun != b.batchRun,
      builder: (context, state) {
        final cubit = context.read<BleConsoleCubit>();
        return Column(
          children: [
            SerialToolBar(
              note: t.ble.batch.bar,
              actions: [
                SerialButton(
                  label: t.common.add,
                  small: true,
                  onPressed: () async {
                    final job = await showBleBatchEditor(context);
                    if (job != null) cubit.saveBatch(job);
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final job in state.batch)
                    SerialItemRow(
                      leading: SerialButton(
                        label: t.serial.batch.start,
                        small: true,
                        primary: true,
                        onPressed: () => cubit.runBatch(job.id),
                      ),
                      title: job.name,
                      detail: '${job.steps.length}',
                      menu: [
                        SerialMenuAction(
                          label: t.common.edit,
                          onTap: () async {
                            final next = await showBleBatchEditor(
                              context,
                              initial: job,
                            );
                            if (next != null) cubit.saveBatch(next);
                          },
                        ),
                        SerialMenuAction(
                          label: t.common.delete,
                          danger: true,
                          onTap: () => showSerialDelete(
                            context,
                            message: t.ble.dialog.deleteBatch,
                            onDelete: () => cubit.deleteBatch(job.id),
                          ),
                        ),
                      ],
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

class _ReplyTab extends StatelessWidget {
  const _ReplyTab();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final r = t.serial.reply;
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      buildWhen: (a, b) => a.rules != b.rules,
      builder: (context, state) {
        final cubit = context.read<BleConsoleCubit>();
        final palette = SerialPalette.of(context);
        final folders = state.rules.folders;

        Future<void> editRule(ReplyRule? initial, {String? folderId}) async {
          final draft = await showBleRuleEditor(
            context,
            initial: initial,
            folders: folders,
            folderId: initial != null
                ? state.rules.folderIdOf(initial.id)
                : folderId,
          );
          if (draft != null) {
            cubit.saveRule(draft.rule, folderId: draft.folderId);
          }
        }

        Future<void> editFolder(ReplyFolder? existing) async {
          final name = await showBleReplyFolderEditor(
            context,
            existing: existing,
            folders: folders,
          );
          if (name != null) cubit.upsertReplyFolder(existing?.id, name);
        }

        Widget ruleRow(ReplyRule rule, {bool indent = false}) {
          final row = SerialItemRow(
            indent: indent,
            leading: SerialSwitch(
              on: rule.enabled,
              onTap: () => cubit.toggleRule(rule.id),
            ),
            title: rule.name,
            detail: '${rule.pattern} · ${rule.hits}',
            menu: [
              SerialMenuAction(
                label: t.common.edit,
                onTap: () => editRule(rule),
              ),
              SerialMenuAction(
                label: t.common.delete,
                danger: true,
                onTap: () => showSerialDelete(
                  context,
                  message: t.ble.dialog.deleteRule,
                  onDelete: () => cubit.deleteRule(rule.id),
                ),
              ),
            ],
          );
          return _BleReplyRuleDrag(rule: rule, child: row);
        }

        return Column(
          children: [
            _BleReplyRootDrop(
              child: SerialToolBar(
                note: t.ble.reply.explain,
                actions: [
                  SerialButton(
                    label: r.newFolder,
                    small: true,
                    onPressed: () => editFolder(null),
                  ),
                  SerialButton(
                    label: t.common.add,
                    small: true,
                    onPressed: () => editRule(null),
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
                        _BleReplyBeforeDrop(
                          beforeId: node.id,
                          allowFolder: true,
                          child: ruleRow(node),
                        ),
                      ],
                      ReplyFolder() => [
                        // 标题：规则→移入夹；文件夹→插到此夹之前。
                        _BleReplyFolderDrop(
                          folder: node,
                          child: _BleReplyFolderDrag(
                            folder: node,
                            child: _BleReplyFolderRow(
                              folder: node,
                              onRename: () => editFolder(node),
                              onAdd: () => editRule(null, folderId: node.id),
                            ),
                          ),
                        ),
                        if (node.expanded) ...[
                          for (final rule in node.rules)
                            _BleReplyBeforeDrop(
                              beforeId: rule.id,
                              child: ruleRow(rule, indent: true),
                            ),
                          if (node.rules.isEmpty)
                            _BleReplyFolderDrop(
                              folder: node,
                              rulesOnly: true,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.lg,
                                  top: AppSpacing.sm,
                                  bottom: AppSpacing.sm,
                                ),
                                child: Text(
                                  r.folderEmpty,
                                  style: AppTextStyles.caption(
                                    Theme.of(context).colorScheme,
                                  ).copyWith(color: palette.muted),
                                ),
                              ),
                            ),
                        ],
                      ],
                    },
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BleReplyRootDrop extends StatelessWidget {
  const _BleReplyRootDrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BleConsoleCubit>();
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
        return _BleReplyDropHighlight(
          hot: hot,
          label: r.dropRoot,
          child: child,
        );
      },
    );
  }
}

class _BleReplyBeforeDrop extends StatelessWidget {
  const _BleReplyBeforeDrop({
    required this.beforeId,
    required this.child,
    this.allowFolder = false,
  });

  final String beforeId;
  final Widget child;
  final bool allowFolder;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BleConsoleCubit>();
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
        return _BleReplyDropHighlight(
          hot: hot,
          label: r.dropBefore,
          child: child,
        );
      },
    );
  }
}

class _BleReplyDropHighlight extends StatelessWidget {
  const _BleReplyDropHighlight({
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

class _BleReplyRuleDrag extends StatelessWidget {
  const _BleReplyRuleDrag({required this.rule, required this.child});

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

class _BleReplyFolderDrag extends StatelessWidget {
  const _BleReplyFolderDrag({required this.folder, required this.child});

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

class _BleReplyFolderDrop extends StatelessWidget {
  const _BleReplyFolderDrop({
    required this.folder,
    required this.child,
    this.rulesOnly = false,
  });

  final ReplyFolder folder;
  final Widget child;
  final bool rulesOnly;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BleConsoleCubit>();
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
        return _BleReplyDropHighlight(
          hot: hot,
          label: draggingFolder ? r.dropBefore : r.dropFolder,
          child: child,
        );
      },
    );
  }
}

class _BleReplyFolderRow extends StatelessWidget {
  const _BleReplyFolderRow({
    required this.folder,
    required this.onRename,
    required this.onAdd,
  });

  final ReplyFolder folder;
  final VoidCallback onRename;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final r = t.serial.reply;
    final cubit = context.read<BleConsoleCubit>();
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final count = folder.rules.length;
    return SerialContextMenu(
      menu: [
        SerialMenuAction(label: r.rename, onTap: onRename),
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
              SerialLinkButton(label: r.add, onPressed: onAdd),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      buildWhen: (a, b) => a.history != b.history || a.pinWrite != b.pinWrite,
      builder: (context, state) {
        if (state.history.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              t.ble.history.empty,
              style: AppTextStyles.caption(
                Theme.of(context).colorScheme,
              ).copyWith(color: SerialPalette.of(context).muted),
            ),
          );
        }
        final cubit = context.read<BleConsoleCubit>();
        return ListView(
          children: [
            for (final item in state.history)
              SerialItemRow(
                leading: SerialButton(
                  label: t.ble.send,
                  small: true,
                  onPressed: () => cubit.resendHistory(item.text),
                ),
                title: item.text,
                detail: state.pinWrite?.uuid ?? t.ble.pin.unpinned,
                monoTitle: true,
              ),
          ],
        );
      },
    );
  }
}

class _ScriptTab extends StatelessWidget {
  const _ScriptTab();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      buildWhen: (a, b) => a.scripts != b.scripts,
      builder: (context, state) {
        final cubit = context.read<BleConsoleCubit>();
        return Column(
          children: [
            SerialToolBar(
              note: t.ble.script.explain,
              actions: [
                SerialButton(
                  label: t.common.add,
                  small: true,
                  onPressed: () async {
                    final script = await showBleScriptEditor(context);
                    if (script != null) cubit.saveScript(script);
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final script in state.scripts)
                    SerialItemRow(
                      leading: SerialSwitch(
                        on: script.enabled,
                        onTap: () => cubit.toggleScript(script.id),
                      ),
                      title: script.name,
                      detail: script.enabled
                          ? t.serial.script.autoOn
                          : t.serial.script.autoOff,
                      menu: [
                        SerialMenuAction(
                          label: t.common.edit,
                          onTap: () async {
                            final next = await showBleScriptEditor(
                              context,
                              initial: script,
                            );
                            if (next != null) cubit.saveScript(next);
                          },
                        ),
                        SerialMenuAction(
                          label: t.common.delete,
                          danger: true,
                          onTap: () => showSerialDelete(
                            context,
                            message: t.ble.dialog.deleteScript,
                            onDelete: () => cubit.deleteScript(script.id),
                          ),
                        ),
                      ],
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
