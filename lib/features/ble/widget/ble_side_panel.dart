import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../cubit/ble_console_cubit.dart';
import '../cubit/ble_console_state.dart';
import '../model/ble_models.dart';

class BleSidePanel extends StatelessWidget {
  const BleSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(right: 2),
      children: const [
        _DeviceGroup(),
        SizedBox(height: AppSpacing.xs + 2),
        _PinGroup(),
      ],
    );
  }
}

class _DeviceGroup extends StatelessWidget {
  const _DeviceGroup();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      buildWhen: (a, b) =>
          a.filter != b.filter ||
          a.scanning != b.scanning ||
          a.scanned != b.scanned ||
          a.adapterReady != b.adapterReady ||
          a.devices != b.devices ||
          a.selectedId != b.selectedId ||
          a.connected != b.connected ||
          a.connecting != b.connecting,
      builder: (context, state) {
        final cubit = context.read<BleConsoleCubit>();
        final list = state.visibleDevices;
        return SerialGroup(
          title: t.ble.scan.title,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SerialLamp(color: state.adapterReady ? palette.on : palette.off),
              const SizedBox(width: AppSpacing.xs),
              Text(
                state.adapterReady ? t.ble.scan.ready : t.ble.scan.adapterOff,
                style: AppTextStyles.caption(
                  Theme.of(context).colorScheme,
                ).copyWith(color: palette.muted),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CommitField(
                      value: state.filter,
                      hint: t.ble.scan.filter,
                      onCommit: cubit.setFilter,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SerialButton(
                    label: state.scanning ? t.ble.scan.scanning : t.ble.scan.scan,
                    small: true,
                    onPressed: state.scanning ? null : cubit.scan,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: palette.line),
                    borderRadius: BorderRadius.circular(
                      SerialMetrics.controlRadius,
                    ),
                    color: palette.field,
                  ),
                  child: list.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(
                            !state.scanned
                                ? t.ble.scan.notScanned
                                : t.ble.scan.empty,
                            style: AppTextStyles.caption(
                              Theme.of(context).colorScheme,
                            ).copyWith(color: palette.muted),
                          ),
                        )
                      : ListView(
                          children: [
                            for (final device in list)
                              InkWell(
                                onTap: state.connected
                                    ? null
                                    : () => cubit.selectDevice(device.id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs + 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              device.label,
                                              style: AppTextStyles.caption(
                                                Theme.of(context).colorScheme,
                                              ).copyWith(
                                                color: palette.text,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              device.address,
                                              style: AppTextStyles.mono(
                                                Theme.of(context).colorScheme,
                                                fontSize: 12,
                                                color: palette.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (device.id == state.selectedId)
                                        Icon(
                                          Icons.check,
                                          size: 16,
                                          color: palette.accent,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SerialButton(
                label: state.connecting
                    ? t.ble.connecting
                    : state.connected
                    ? t.ble.disconnect
                    : t.ble.connect,
                primary: !state.connected,
                expand: true,
                height: SerialMetrics.openButton,
                leading: SerialLamp(
                  color: state.connected ? palette.on : palette.off,
                ),
                onPressed: state.connecting ? null : cubit.toggleConnect,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PinGroup extends StatelessWidget {
  const _PinGroup();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      buildWhen: (a, b) =>
          a.connected != b.connected ||
          a.services != b.services ||
          a.pinNotify != b.pinNotify ||
          a.pinWrite != b.pinWrite ||
          a.writeType != b.writeType ||
          a.mtu != b.mtu ||
          a.chunkSize != b.chunkSize,
      builder: (context, state) {
        final cubit = context.read<BleConsoleCubit>();
        return SerialGroup(
          title: t.ble.pin.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PinSlot(
                label: t.ble.pin.notify,
                value: state.pinNotify?.uuid ?? t.ble.pin.unpinned,
              ),
              const SizedBox(height: AppSpacing.xs),
              _PinSlot(
                label: t.ble.pin.write,
                value: state.pinWrite?.uuid ?? t.ble.pin.unpinned,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!state.connected)
                Text(
                  t.ble.pin.needConnect,
                  style: AppTextStyles.caption(
                    Theme.of(context).colorScheme,
                  ).copyWith(color: palette.muted),
                )
              else
                for (final service in state.services) ...[
                  InkWell(
                    onTap: () => cubit.toggleService(service.uuid),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${service.expanded ? '▾' : '▸'} ${service.title}',
                        style: AppTextStyles.caption(
                          Theme.of(context).colorScheme,
                        ).copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (service.expanded)
                    for (final char in service.characteristics)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          bottom: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                char.title,
                                style: AppTextStyles.caption(
                                  Theme.of(context).colorScheme,
                                ).copyWith(color: palette.text),
                              ),
                            ),
                            if (char.pinNotify)
                              SerialButton(
                                label:
                                    state.pinNotify?.uuid == char.uuid
                                    ? t.ble.pin.pinnedNotify
                                    : t.ble.pin.pinNotify,
                                small: true,
                                accent: state.pinNotify?.uuid == char.uuid,
                                onPressed: () => cubit.pinNotify(char),
                              ),
                            if (char.pinWrite) ...[
                              const SizedBox(width: AppSpacing.xs),
                              SerialButton(
                                label:
                                    state.pinWrite?.uuid == char.uuid
                                    ? t.ble.pin.pinnedWrite
                                    : t.ble.pin.pinWrite,
                                small: true,
                                accent: state.pinWrite?.uuid == char.uuid,
                                onPressed: () => cubit.pinWrite(char),
                              ),
                            ],
                          ],
                        ),
                      ),
                ],
              const SizedBox(height: AppSpacing.sm),
              _Field(
                label: t.ble.writeType,
                child: SerialDropdown<BleWriteType>(
                  value: state.writeType,
                  height: SerialMetrics.controlSm,
                  items: [
                    (
                      value: BleWriteType.withoutResponse,
                      label: t.ble.withoutResponse,
                    ),
                    (
                      value: BleWriteType.withResponse,
                      label: t.ble.withResponse,
                    ),
                  ],
                  onChanged: cubit.setWriteType,
                ),
              ),
              _Field(
                label: t.ble.mtu,
                child: _CommitField(
                  value: '${state.mtu}',
                  numeric: true,
                  onCommit: cubit.setMtu,
                ),
              ),
              _Field(
                label: t.ble.chunk,
                child: _CommitField(
                  value: '${state.chunkSize}',
                  numeric: true,
                  onCommit: cubit.setChunkSize,
                ),
              ),
              Text(
                t.ble.pin.note,
                style: AppTextStyles.caption(
                  Theme.of(context).colorScheme,
                ).copyWith(color: palette.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PinSlot extends StatelessWidget {
  const _PinSlot({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: palette.field,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(SerialMetrics.controlRadius),
      ),
      child: Text.rich(
        TextSpan(
          text: '$label ',
          style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
          children: [
            TextSpan(
              text: value,
              style: AppTextStyles.mono(
                cs,
                fontSize: 12,
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommitField extends StatefulWidget {
  const _CommitField({
    required this.value,
    required this.onCommit,
    this.hint,
    this.numeric = false,
  });

  final String value;
  final ValueChanged<String> onCommit;
  final String? hint;
  final bool numeric;

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
      hint: widget.hint,
      height: SerialMetrics.controlSm,
      keyboardType: widget.numeric ? TextInputType.number : null,
      inputFormatters: widget.numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      onChanged: widget.onCommit,
      onSubmitted: widget.onCommit,
      onFocusLost: () => widget.onCommit(_controller.text),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

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
              style: AppTextStyles.caption(
                Theme.of(context).colorScheme,
              ).copyWith(color: palette.muted, fontSize: 13),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}
