import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
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
        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border.all(color: palette.line),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            children: [
              SizedBox(
                height: SerialMetrics.logHead,
                child: Row(
                  children: [
                    for (final tab in kBleToolTabs)
                      _Tab(
                        label: _label(t, tab),
                        on: state.tab == tab,
                        onTap: () => cubit.setTab(tab),
                        script: tab == ToolTab.script,
                      ),
                  ],
                ),
              ),
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

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.on,
    required this.onTap,
    this.script = false,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;
  final bool script;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              left: script ? BorderSide(color: palette.line) : BorderSide.none,
              bottom: BorderSide(
                color: on ? palette.accent : palette.line,
                width: on ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(cs).copyWith(
              color: on ? palette.text : palette.muted,
              fontWeight: on ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickTab extends StatelessWidget {
  const _QuickTab();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      buildWhen: (a, b) => a.quick != b.quick || a.pinWrite != b.pinWrite,
      builder: (context, state) {
        final cubit = context.read<BleConsoleCubit>();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.pinWrite == null
                          ? t.ble.quick.targetNone
                          : t.ble.quick.target(uuid: state.pinWrite!.uuid),
                      style: AppTextStyles.caption(
                        Theme.of(context).colorScheme,
                      ).copyWith(color: palette.muted),
                    ),
                  ),
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
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final item in state.quick)
                    _Row(
                      leading: SerialButton(
                        label: t.ble.send,
                        small: true,
                        primary: true,
                        onPressed: () => cubit.sendQuick(item.id),
                      ),
                      title: '${item.name} ${item.key}',
                      subtitle: item.data,
                      onEdit: () async {
                        final next = await showBleQuickEditor(
                          context,
                          initial: item,
                        );
                        if (next != null) cubit.saveQuick(next);
                      },
                      onDelete: () => cubit.deleteQuick(item.id),
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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.ble.batch.bar,
                      style: AppTextStyles.caption(
                        Theme.of(context).colorScheme,
                      ).copyWith(color: SerialPalette.of(context).muted),
                    ),
                  ),
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
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final job in state.batch)
                    _Row(
                      leading: SerialButton(
                        label: t.serial.batch.start,
                        small: true,
                        primary: true,
                        onPressed: () => cubit.runBatch(job.id),
                      ),
                      title: job.name,
                      subtitle: '${job.steps.length}',
                      onEdit: () async {
                        final next = await showBleBatchEditor(
                          context,
                          initial: job,
                        );
                        if (next != null) cubit.saveBatch(next);
                      },
                      onDelete: () => cubit.deleteBatch(job.id),
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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.ble.reply.explain,
                      style: AppTextStyles.caption(
                        Theme.of(context).colorScheme,
                      ).copyWith(color: SerialPalette.of(context).muted),
                    ),
                  ),
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
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final rule in state.rules)
                    _Row(
                      leading: SerialSwitch(
                        on: rule.enabled,
                        onTap: () => cubit.toggleRule(rule.id),
                      ),
                      title: rule.name,
                      subtitle: '${rule.pattern} · ${rule.hits}',
                      onEdit: () async {
                        final next = await showBleRuleEditor(
                          context,
                          initial: rule,
                        );
                        if (next != null) cubit.saveRule(next);
                      },
                      onDelete: () => cubit.deleteRule(rule.id),
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
              _Row(
                leading: SerialButton(
                  label: t.ble.send,
                  small: true,
                  onPressed: () => cubit.resendHistory(item.text),
                ),
                title: item.text,
                subtitle: state.pinWrite?.uuid ?? t.ble.pin.unpinned,
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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.ble.script.explain,
                      style: AppTextStyles.caption(
                        Theme.of(context).colorScheme,
                      ).copyWith(color: SerialPalette.of(context).muted),
                    ),
                  ),
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
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final script in state.scripts)
                    _Row(
                      leading: SerialSwitch(
                        on: script.enabled,
                        onTap: () => cubit.toggleScript(script.id),
                      ),
                      title: script.name,
                      subtitle: script.enabled
                          ? t.serial.script.autoOn
                          : t.serial.script.autoOff,
                      onEdit: () async {
                        final next = await showBleScriptEditor(
                          context,
                          initial: script,
                        );
                        if (next != null) cubit.saveScript(next);
                      },
                      onDelete: () => cubit.deleteScript(script.id),
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

class _Row extends StatelessWidget {
  const _Row({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.onDelete,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(
                    cs,
                  ).copyWith(color: palette.text, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
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
          if (onEdit != null)
            SerialLinkButton(label: tEdit(context), onPressed: onEdit!),
          if (onDelete != null)
            SerialLinkButton(label: tDelete(context), onPressed: onDelete!),
        ],
      ),
    );
  }
}

String tEdit(BuildContext context) => Translations.of(context).common.edit;

String tDelete(BuildContext context) => Translations.of(context).common.delete;
