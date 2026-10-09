import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/serial_console_cubit.dart';
import '../cubit/serial_console_state.dart';
import '../model/serial_models.dart';
import '../serial_metrics.dart';
import 'serial_chrome.dart';

class SerialSidePanel extends StatelessWidget {
  const SerialSidePanel({super.key, required this.onOpenTools});

  final ValueChanged<ToolTab> onOpenTools;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(right: 2),
      children: [
        const _PortGroup(),
        const SizedBox(height: AppSpacing.xs + 2),
        const _RxGroup(),
        const SizedBox(height: AppSpacing.xs + 2),
        _TxGroup(onOpenTools: onOpenTools),
      ],
    );
  }
}

class _PortGroup extends StatelessWidget {
  const _PortGroup();

  @override
  Widget build(BuildContext context) {
        final t = Translations.of(context);
        final palette = SerialPalette.of(context);
        return BlocBuilder<SerialConsoleCubit, SerialConsoleState>(
      buildWhen: (a, b) =>
          a.ports != b.ports ||
          a.portName != b.portName ||
          a.baud != b.baud ||
          a.parity != b.parity ||
          a.dataBits != b.dataBits ||
          a.stopBits != b.stopBits ||
          a.flow != b.flow ||
          a.open != b.open ||
          a.dtr != b.dtr ||
          a.rts != b.rts ||
          a.pins != b.pins,
      builder: (context, state) {
        final cubit = context.read<SerialConsoleCubit>();
        final port = t.serial.port;
        return SerialGroup(
          title: port.title,
          child: Column(
            children: [
              _FieldRow(
                label: port.name,
                child: Row(
                  children: [
                    Expanded(
                      child: SerialDropdown<String>(
                        value: state.portName ?? '',
                        enabled: !state.open,
                        items: [
                          if (state.ports.isEmpty)
                            (value: '', label: port.empty),
                          for (final item in state.ports)
                            (value: item.name, label: item.label),
                        ],
                        onChanged: cubit.setPort,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    SerialButton(
                      label: port.refresh,
                      small: true,
                      onPressed: cubit.refreshPorts,
                    ),
                  ],
                ),
              ),
              _FieldRow(
                label: port.baud,
                child: _CommitField(
                  value: '${state.baud}',
                  mono: false,
                  numeric: true,
                  onCommit: (text) => cubit.setBaud(int.tryParse(text) ?? 0),
                ),
              ),
              _FieldRow(
                label: port.parity,
                child: SerialDropdown<Parity>(
                  value: state.parity,
                  items: [
                    for (final item in Parity.values)
                      (value: item, label: _parityLabel(t, item)),
                  ],
                  onChanged: cubit.setParity,
                ),
              ),
              _FieldRow(
                label: port.dataBits,
                child: SerialDropdown<int>(
                  value: state.dataBits,
                  items: [
                    for (final bits in [5, 6, 7, 8])
                      (value: bits, label: '$bits'),
                  ],
                  onChanged: cubit.setDataBits,
                ),
              ),
              _FieldRow(
                label: port.stopBits,
                child: SerialDropdown<StopBits>(
                  value: state.stopBits,
                  items: [
                    for (final item in StopBits.values)
                      (value: item, label: item.label),
                  ],
                  onChanged: cubit.setStopBits,
                ),
              ),
              _FieldRow(
                label: port.flow,
                child: SerialDropdown<FlowControl>(
                  value: state.flow,
                  items: [
                    for (final item in FlowControl.values)
                      (value: item, label: item.label),
                  ],
                  onChanged: cubit.setFlow,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SerialButton(
                label: state.open ? port.close : port.open,
                expand: true,
                height: SerialMetrics.openButton,
                primary: !state.open,
                leading: SerialLamp(
                  color: state.open ? palette.on : palette.off,
                ),
                onPressed: cubit.toggleOpen,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _Signal(
                    label: 'DTR',
                    value: state.dtr,
                    onChanged: cubit.setDtr,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _Signal(
                    label: 'RTS',
                    value: state.rts,
                    onChanged: cubit.setRts,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.line2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
                  child: Tooltip(
                    message: port.pinsTip,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Pin('DCD', state.pins.dcd, palette),
                        _Pin('DSR', state.pins.dsr, palette),
                        _Pin('CTS', state.pins.cts, palette),
                        _Pin('RI', state.pins.ri, palette),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RxGroup extends StatelessWidget {
  const _RxGroup();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return BlocBuilder<SerialConsoleCubit, SerialConsoleState>(
      buildWhen: (a, b) =>
          a.rxFormat != b.rxFormat ||
          a.logMode != b.logMode ||
          a.wrap != b.wrap ||
          a.hideRx != b.hideRx ||
          a.saveActive != b.saveActive ||
          a.autoScroll != b.autoScroll ||
          a.packetTimeoutMs != b.packetTimeoutMs,
      builder: (context, state) {
        final cubit = context.read<SerialConsoleCubit>();
        final rx = t.serial.rx;
        return SerialGroup(
          title: rx.title,
          trailing: _FormatRadios(
            value: state.rxFormat,
            onChanged: cubit.setRxFormat,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SerialCheck(
                label: rx.logMode,
                value: state.logMode,
                onChanged: cubit.setLogMode,
              ),
              SerialCheck(
                label: rx.wrap,
                value: state.wrap,
                onChanged: cubit.setWrap,
              ),
              SerialCheck(
                label: rx.hide,
                value: state.hideRx,
                onChanged: cubit.setHideRx,
              ),
              SerialCheck(
                label: rx.save,
                value: state.saveActive,
                onChanged: cubit.setSaveRx,
              ),
              SerialCheck(
                label: rx.scroll,
                value: state.autoScroll,
                onChanged: cubit.setAutoScroll,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rx.timeout,
                      style: AppTextStyles.body(Theme.of(context).colorScheme)
                          .copyWith(color: SerialPalette.of(context).text),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: _CommitField(
                      value: '${state.packetTimeoutMs}',
                      numeric: true,
                      height: SerialMetrics.buttonSm,
                      onCommit: (text) =>
                          cubit.setPacketTimeout(int.tryParse(text) ?? -1),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'ms',
                    style: AppTextStyles.mono(
                      Theme.of(context).colorScheme,
                      fontSize: 12,
                      color: SerialPalette.of(context).muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  SerialLinkButton(
                    label: rx.saveData,
                    onPressed: cubit.saveLog,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SerialLinkButton(
                    label: rx.clear,
                    onPressed: cubit.clearLog,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TxGroup extends StatelessWidget {
  const _TxGroup({required this.onOpenTools});

  final ValueChanged<ToolTab> onOpenTools;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return BlocBuilder<SerialConsoleCubit, SerialConsoleState>(
      buildWhen: (a, b) =>
          a.txFormat != b.txFormat ||
          a.escape != b.escape ||
          a.atCrlf != b.atCrlf ||
          a.crlf != b.crlf ||
          a.checksum != b.checksum ||
          a.clearAfterSend != b.clearAfterSend ||
          a.fileName != b.fileName ||
          a.fileBytes != b.fileBytes ||
          a.loopEnabled != b.loopEnabled ||
          a.loopPeriodMs != b.loopPeriodMs,
      builder: (context, state) {
        final cubit = context.read<SerialConsoleCubit>();
        final tx = t.serial.tx;
        final palette = SerialPalette.of(context);
        return SerialGroup(
          title: tx.title,
          trailing: _FormatRadios(
            value: state.txFormat,
            onChanged: cubit.setTxFormat,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SerialCheck(
                label: tx.escape,
                value: state.escape,
                onChanged: cubit.setEscape,
              ),
              SerialCheck(
                label: tx.at,
                value: state.atCrlf,
                onChanged: cubit.setAtCrlf,
              ),
              SerialCheck(
                label: tx.crlf,
                value: state.crlf,
                onChanged: cubit.setCrlf,
              ),
              Row(
                children: [
                  Expanded(
                    child: SerialCheck(
                      label: tx.checksum,
                      value: state.checksum != ChecksumKind.none,
                      onChanged: (on) => cubit.setChecksum(
                        on ? ChecksumKind.crc16 : ChecksumKind.none,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: SerialDropdown<ChecksumKind>(
                      value: state.checksum == ChecksumKind.none
                          ? ChecksumKind.crc16
                          : state.checksum,
                      height: SerialMetrics.buttonSm,
                      items: [
                        for (final kind in ChecksumKind.values)
                          if (kind != ChecksumKind.none)
                            (value: kind, label: _checksum(t, kind)),
                      ],
                      onChanged: cubit.setChecksum,
                    ),
                  ),
                ],
              ),
              SerialCheck(
                label: tx.clear,
                value: state.clearAfterSend,
                onChanged: cubit.setClearAfterSend,
              ),
              SerialCheck(
                label: tx.file,
                value: state.fileBytes != null,
                onChanged: cubit.setFileSource,
              ),
              if (state.fileName != null && state.fileBytes != null)
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Text(
                    t.serial.status.fileMeta(
                      name: state.fileName!,
                      count: state.fileBytes!.length,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mono(
                      Theme.of(context).colorScheme,
                      fontSize: 12,
                      color: palette.muted,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: SerialCheck(
                      label: tx.loop,
                      value: state.loopEnabled,
                      onChanged: cubit.setLoopEnabled,
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: _CommitField(
                      value: '${state.loopPeriodMs}',
                      numeric: true,
                      height: SerialMetrics.buttonSm,
                      onCommit: (text) =>
                          cubit.setLoopPeriod(int.tryParse(text) ?? 0),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'ms',
                    style: AppTextStyles.mono(
                      Theme.of(context).colorScheme,
                      fontSize: 12,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  SerialLinkButton(
                    label: tx.quick,
                    onPressed: () => onOpenTools(ToolTab.quick),
                  ),
                  SerialLinkButton(
                    label: tx.history,
                    onPressed: () => onOpenTools(ToolTab.history),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SerialMetrics.formGap),
      child: Row(
        children: [
          SizedBox(
            width: SerialMetrics.labelCol,
            child: Text(
              label,
              style: AppTextStyles.caption(Theme.of(context).colorScheme)
                  .copyWith(color: palette.muted, fontSize: 13),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CommitField extends StatefulWidget {
  const _CommitField({
    required this.value,
    required this.onCommit,
    this.numeric = false,
    this.mono = true,
    this.height = SerialMetrics.controlSm,
  });

  final String value;
  final ValueChanged<String> onCommit;
  final bool numeric;
  final bool mono;
  final double height;

  @override
  State<_CommitField> createState() => _CommitFieldState();
}

class _CommitFieldState extends State<_CommitField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(covariant _CommitField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SerialField(
      controller: _controller,
      focusNode: _focus,
      mono: widget.mono,
      height: widget.height,
      keyboardType: widget.numeric ? TextInputType.number : null,
      inputFormatters: widget.numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      onSubmitted: widget.onCommit,
      onFocusLost: () => widget.onCommit(_controller.text),
    );
  }
}

class _FormatRadios extends StatelessWidget {
  const _FormatRadios({required this.value, required this.onChanged});

  final DataFormat value;
  final ValueChanged<DataFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Radio(
          label: t.serial.mark.ascii,
          selected: value == DataFormat.ascii,
          onTap: () => onChanged(DataFormat.ascii),
        ),
        const SizedBox(width: AppSpacing.md),
        _Radio(
          label: t.serial.mark.hex,
          selected: value == DataFormat.hex,
          onTap: () => onChanged(DataFormat.hex),
        ),
      ],
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
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
          Text(
            label,
            style: AppTextStyles.body(Theme.of(context).colorScheme).copyWith(
              color: palette.text,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _Signal extends StatelessWidget {
  const _Signal({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: value,
              onChanged: (next) => onChanged(next ?? false),
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            label,
            style: AppTextStyles.body(Theme.of(context).colorScheme).copyWith(
              color: SerialPalette.of(context).text,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin(this.label, this.on, this.palette);

  final String label;
  final bool on;
  final SerialPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SerialLamp(
          size: SerialMetrics.pin,
          color: on ? palette.on : palette.lampIdle,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.mono(
            Theme.of(context).colorScheme,
            fontSize: 12,
            color: palette.muted,
          ),
        ),
      ],
    );
  }
}

String _parityLabel(Translations t, Parity parity) => switch (parity) {
      Parity.none => t.serial.parityOpt.none,
      Parity.odd => t.serial.parityOpt.odd,
      Parity.even => t.serial.parityOpt.even,
      Parity.mark => t.serial.parityOpt.mark,
      Parity.space => t.serial.parityOpt.space,
    };

String _checksum(Translations t, ChecksumKind kind) => switch (kind) {
      ChecksumKind.none => t.serial.flowOpt.none,
      ChecksumKind.sum => t.serial.checksum.sum,
      ChecksumKind.xor => t.serial.checksum.xor,
      ChecksumKind.lrc => t.serial.checksum.lrc,
      ChecksumKind.crc8 => t.serial.checksum.crc8,
      ChecksumKind.crc16 => t.serial.checksum.crc16,
      ChecksumKind.crc32 => t.serial.checksum.crc32,
    };
