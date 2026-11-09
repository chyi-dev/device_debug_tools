import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/socket_console_cubit.dart';
import '../cubit/socket_console_state.dart';
import '../../serial/model/serial_models.dart';
import '../model/socket_models.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import 'socket_editors.dart';

class SocketSidePanel extends StatelessWidget {
  const SocketSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    // 外壳 AppConsoleShell 已有 8px，这里不再垫一层。
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        _ConnGroup(),
        SizedBox(height: AppSpacing.sm),
        _RxGroup(),
        SizedBox(height: AppSpacing.sm),
        _TxGroup(),
      ],
    );
  }
}

class _ConnGroup extends StatelessWidget {
  const _ConnGroup();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    return BlocBuilder<SocketConsoleCubit, SocketConsoleState>(
      buildWhen: (a, b) =>
          a.protocol != b.protocol ||
          a.role != b.role ||
          a.host != b.host ||
          a.port != b.port ||
          a.remoteHost != b.remoteHost ||
          a.remotePort != b.remotePort ||
          a.open != b.open ||
          a.busy != b.busy ||
          a.peers != b.peers ||
          a.selectedPeerId != b.selectedPeerId,
      builder: (context, state) {
        final cubit = context.read<SocketConsoleCubit>();
        final c = t.socket.conn;
        return SerialGroup(
          title: c.title,
          child: Column(
            children: [
              if (state.isTcp) ...[
                SerialFieldRow(
                  label: c.role,
                  child: SerialDropdown<SocketRole>(
                    value: state.role,
                    enabled: !state.open,
                    items: [
                      (
                        value: SocketRole.client,
                        label: c.roleClient,
                      ),
                      (
                        value: SocketRole.server,
                        label: c.roleServer,
                      ),
                    ],
                    onChanged: cubit.setRole,
                  ),
                ),
              ],
              SerialFieldRow(
                label: c.host,
                child: _CommitField(
                  value: state.host,
                  enabled: !state.open,
                  onCommit: cubit.setHost,
                ),
              ),
              SerialFieldRow(
                label: c.port,
                bottomGap: state.isUdp || state.isTcpServer,
                child: _CommitField(
                  value: '${state.port}',
                  numeric: true,
                  enabled: !state.open,
                  onCommit: (text) =>
                      cubit.setPort(int.tryParse(text) ?? -1),
                ),
              ),
              if (state.isUdp) ...[
                SerialSectionLabel(c.remoteTitle),
                SerialFieldRow(
                  label: c.remoteHost,
                  child: _CommitField(
                    value: state.remoteHost,
                    enabled: !state.open,
                    onCommit: cubit.setRemoteHost,
                  ),
                ),
                SerialFieldRow(
                  label: c.remotePort,
                  bottomGap: false,
                  child: _CommitField(
                    value: '${state.remotePort}',
                    numeric: true,
                    enabled: !state.open,
                    onCommit: (text) =>
                        cubit.setRemotePort(int.tryParse(text) ?? -1),
                  ),
                ),
              ],
              if (state.isTcpServer) ...[
                SerialFieldRow(
                  label: c.peers,
                  bottomGap: false,
                  child: SerialDropdown<String?>(
                    value: state.selectedPeerId,
                    enabled: state.open,
                    items: [
                      (
                        value: null,
                        label: c.peerAll(count: state.peers.length),
                      ),
                      for (final peer in state.peers)
                        (value: peer.id, label: peer.address),
                    ],
                    onChanged: cubit.selectPeer,
                  ),
                ),
                if (state.open && state.peers.isEmpty)
                  Text(
                    c.emptyPeers,
                    style: AppTextStyles.caption(
                      Theme.of(context).colorScheme,
                    ).copyWith(color: palette.muted),
                  ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SerialButton(
                label: state.open ? c.close : c.open,
                expand: true,
                height: SerialMetrics.openButton,
                primary: !state.open,
                leading: SerialLamp(
                  color: state.open ? palette.on : palette.off,
                ),
                onPressed: state.busy ? null : cubit.toggleOpen,
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
    return BlocBuilder<SocketConsoleCubit, SocketConsoleState>(
      buildWhen: (a, b) =>
          a.rxFormat != b.rxFormat ||
          a.logMode != b.logMode ||
          a.wrap != b.wrap ||
          a.hideRx != b.hideRx ||
          a.saveActive != b.saveActive ||
          a.autoScroll != b.autoScroll ||
          a.packetTimeoutMs != b.packetTimeoutMs,
      builder: (context, state) {
        final cubit = context.read<SocketConsoleCubit>();
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
                      style: AppTextStyles.body(
                        Theme.of(context).colorScheme,
                      ).copyWith(color: SerialPalette.of(context).text),
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
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  SerialButton(
                    label: rx.saveData,
                    small: true,
                    accent: true,
                    onPressed: cubit.saveLog,
                  ),
                  SerialButton(
                    label: rx.clear,
                    small: true,
                    accent: true,
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
  const _TxGroup();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return BlocBuilder<SocketConsoleCubit, SocketConsoleState>(
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
        final cubit = context.read<SocketConsoleCubit>();
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
              if (state.fileName != null && state.fileBytes != null)
                Row(
                  children: [
                    Expanded(
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
                    SerialLinkButton(
                      label: t.serial.dialog.remove,
                      danger: true,
                      onPressed: () => cubit.setFileSource(false),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SerialButton(
                      label: tx.file,
                      small: true,
                      accent: true,
                      expand: true,
                      onPressed: () => cubit.setFileSource(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Tooltip(
                    message: tx.fileHelp,
                    child: InkWell(
                      onTap: () => showFileSourceHelp(context),
                      borderRadius: BorderRadius.circular(
                        SerialMetrics.controlRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Icon(
                          Icons.help_outline,
                          size: 16,
                          color: palette.muted,
                        ),
                      ),
                    ),
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

class _CommitField extends StatefulWidget {
  const _CommitField({
    required this.value,
    required this.onCommit,
    this.numeric = false,
    this.enabled = true,
    this.height = SerialMetrics.controlSm,
  });

  final String value;
  final ValueChanged<String> onCommit;
  final bool numeric;
  final bool enabled;
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
      enabled: widget.enabled,
      mono: true,
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
            style: AppTextStyles.body(
              Theme.of(context).colorScheme,
            ).copyWith(color: palette.text, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

String _checksum(Translations t, ChecksumKind kind) => switch (kind) {
  ChecksumKind.none => t.serial.flowOpt.none,
  ChecksumKind.sum => t.serial.checksum.sum,
  ChecksumKind.xor => t.serial.checksum.xor,
  ChecksumKind.lrc => t.serial.checksum.lrc,
  ChecksumKind.crc8 => t.serial.checksum.crc8,
  ChecksumKind.crc16 => t.serial.checksum.crc16,
  ChecksumKind.crc32 => t.serial.checksum.crc32,
};
