import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
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
                child: Row(
                  children: [
                    for (final tab in tabs)
                      if (tab == ToolTab.script) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(width: 1, height: 18, color: palette.line),
                        const SizedBox(width: AppSpacing.xs),
                        _tabButton(
                          context,
                          label: _label(t, tab),
                          active: state.tab == tab,
                          onTap: () => cubit.setTab(tab),
                          padded: true,
                        ),
                      ] else
                        Expanded(
                          child: _tabButton(
                            context,
                            label: _label(t, tab),
                            active: state.tab == tab,
                            onTap: () => cubit.setTab(tab),
                          ),
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
  ToolTab.calc => t.serial.tab.quick,
};

Widget _tabButton(
  BuildContext context, {
  required String label,
  required bool active,
  required VoidCallback onTap,
  bool padded = false,
}) {
  final palette = SerialPalette.of(context);
  return InkWell(
    onTap: onTap,
    child: AnimatedContainer(
      duration: SerialMetrics.motion,
      curve: SerialMetrics.motionCurve,
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
                      leading: SerialButton(
                        label: t.ble.send,
                        small: true,
                        primary: true,
                        onPressed: () => cubit.sendQuick(item.id),
                      ),
                      title: item.name,
                      detail: item.data,
                      trailing: [
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
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      buildWhen: (a, b) => a.rules != b.rules,
      builder: (context, state) {
        final cubit = context.read<BleConsoleCubit>();
        return Column(
          children: [
            SerialToolBar(
              note: t.ble.reply.explain,
              actions: [
                SerialButton(
                  label: t.common.add,
                  small: true,
                  onPressed: () async {
                    final rule = await showBleRuleEditor(context);
                    if (rule != null) cubit.saveRule(rule);
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final rule in state.rules)
                    SerialItemRow(
                      leading: SerialSwitch(
                        on: rule.enabled,
                        onTap: () => cubit.toggleRule(rule.id),
                      ),
                      title: rule.name,
                      detail: '${rule.pattern} · ${rule.hits}',
                      menu: [
                        SerialMenuAction(
                          label: t.common.edit,
                          onTap: () async {
                            final next = await showBleRuleEditor(
                              context,
                              initial: rule,
                            );
                            if (next != null) cubit.saveRule(next);
                          },
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
