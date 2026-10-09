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
import '../model/serial_models.dart';
import '../serial_metrics.dart';
import 'serial_chrome.dart';
import 'serial_editors.dart';
import 'serial_l10n.dart';

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
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
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
                      Expanded(
                        child: InkWell(
                          onTap: () => context.read<SerialConsoleCubit>().setTab(tab),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: state.tab == tab
                                      ? palette.accent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _tabLabel(t, tab),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(cs).copyWith(
                                  color: state.tab == tab
                                      ? palette.text
                                      : palette.muted,
                                  fontWeight: state.tab == tab
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _body(BuildContext context, SerialConsoleState state) {
    return switch (state.tab) {
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
    };

class _Bar extends StatelessWidget {
  const _Bar({required this.note, required this.actions});

  final String note;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              note,
              style: AppTextStyles.caption(Theme.of(context).colorScheme).copyWith(
                color: palette.muted,
              ),
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
    final cubit = context.read<SerialConsoleCubit>();
    return Column(
      children: [
        _Bar(
          note: t.serial.quick.note,
          actions: [
            SerialButton(
              label: t.common.add,
              small: true,
              onPressed: () => showQuickEditor(context),
            ),
          ],
        ),
        Expanded(
          child: state.quick.isEmpty
              ? _Explain(t.serial.quick.empty)
              : ListView(
                  children: [
                    for (final item in state.quick)
                      _ItemRow(
                        leading: SerialButton(
                          label: t.serial.quick.send,
                          small: true,
                          primary: true,
                          onPressed: () => cubit.sendQuick(item.id),
                        ),
                        title: item.name,
                        detail: item.format == DataFormat.ascii
                            ? '${t.serial.mark.ascii} · ${item.data}'
                            : item.data,
                        trailing: [
                          if (item.key.isNotEmpty) _KeyChip(item.key),
                          SerialLinkButton(
                            label: t.common.edit,
                            onPressed: () => showQuickEditor(context, existing: item),
                          ),
                          SerialLinkButton(
                            label: t.common.delete,
                            danger: true,
                            onPressed: () => showSerialDelete(
                              context,
                              message: t.serial.dialog.deleteQuick(name: item.name),
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
    return Column(
      children: [
        _Bar(
          note: '',
          actions: [
            SizedBox(
              width: 140,
              child: SerialDropdown<String>(
                value: selected.id,
                items: [
                  for (final job in state.batch)
                    (value: job.id, label: job.name),
                ],
                onChanged: cubit.selectBatch,
              ),
            ),
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
                    style: AppTextStyles.caption(cs).copyWith(color: palette.muted, fontSize: 13),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  _RepeatBox(
                    value: selected.repeat,
                    onCommit: (value) => cubit.setBatchRepeat(selected.id, value),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    t.serial.batch.rounds,
                    style: AppTextStyles.caption(cs).copyWith(color: palette.muted, fontSize: 13),
                  ),
                ],
              ),
              SerialCheck(
                label: t.serial.batch.stopOnFail,
                value: selected.stopOnFail,
                onChanged: (value) => cubit.setBatchStopOnFail(selected.id, value),
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
                style: AppTextStyles.caption(cs).copyWith(color: palette.muted, fontSize: 13),
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
                : ((run.round - 1) * run.total + run.step) / (run.rounds * run.total),
            color: palette.accent,
            backgroundColor: palette.line2,
          ),
        Expanded(
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
          note: t.serial.reply.note(enabled: enabled, total: state.rules.length),
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
                      '${matchModeLabel(t, rule.match)} ${rule.pattern} → ${rule.replies.map((reply) => '+${reply.delayMs}ms ${reply.data}').join('，')}',
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
                    SerialLinkButton(
                      label: t.common.edit,
                      onPressed: () => showRuleEditor(context, existing: rule),
                    ),
                    SerialLinkButton(
                      label: t.common.delete,
                      danger: true,
                      onPressed: () => showSerialDelete(
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
                              : clockStamp(state.history[i].time!).substring(0, 8),
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
            format == DataFormat.hex ? t.serial.calc.badHex : t.serial.calc.empty,
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
          style: AppTextStyles.caption(cs).copyWith(color: palette.muted, height: 1.6),
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
              style: AppTextStyles.body(cs).copyWith(color: palette.text, fontSize: 13),
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
  });

  final Widget leading;
  final String title;
  final String detail;
  final List<Widget> trailing;
  final bool monoTitle;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return HoverSurface(
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
                        ? AppTextStyles.mono(cs, fontSize: 13, color: palette.text)
                        : AppTextStyles.body(cs).copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mono(cs, fontSize: 12, color: palette.muted),
                  ),
                ],
              ),
            ),
            ...trailing,
          ],
        ),
      ),
    );
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
        style: AppTextStyles.caption(Theme.of(context).colorScheme).copyWith(
          color: palette.muted,
          height: 1.6,
        ),
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
    final style = AppTextStyles.caption(Theme.of(context).colorScheme).copyWith(
      color: palette.muted,
      fontWeight: FontWeight.w600,
    );
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
          SizedBox(width: 28, child: Text(t.serial.batch.colIndex, style: style)),
          SizedBox(width: 72, child: Text(t.serial.batch.colDelay, style: style)),
          Expanded(child: Text(t.serial.batch.colData, style: style)),
          SizedBox(width: 88, child: Text(t.serial.batch.colNote, style: style)),
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
            child: Text(step.data, style: style, overflow: TextOverflow.ellipsis),
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
