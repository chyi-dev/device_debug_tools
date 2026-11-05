import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../cubit/mqtt_console_cubit.dart';
import '../cubit/mqtt_console_state.dart';
import '../model/mqtt_models.dart';
import 'mqtt_l10n.dart';

class MqttSidePanel extends StatelessWidget {
  const MqttSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(right: 2),
      children: const [_ConnGroup()],
    );
  }
}

class _ConnGroup extends StatelessWidget {
  const _ConnGroup();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      buildWhen: (a, b) =>
          a.host != b.host ||
          a.port != b.port ||
          a.scheme != b.scheme ||
          a.wsPath != b.wsPath ||
          a.connecting != b.connecting ||
          a.connected != b.connected ||
          a.version != b.version ||
          a.clientId != b.clientId ||
          a.username != b.username ||
          a.password != b.password ||
          a.caFile != b.caFile ||
          a.clientCert != b.clientCert ||
          a.clientKey != b.clientKey ||
          a.keepAlive != b.keepAlive ||
          a.sessionExpiry != b.sessionExpiry ||
          a.cleanStart != b.cleanStart ||
          a.autoReconnect != b.autoReconnect ||
          a.willTopic != b.willTopic ||
          a.willPayload != b.willPayload ||
          a.willQos != b.willQos ||
          a.willRetain != b.willRetain,
      builder: (context, state) {
        final cubit = context.read<MqttConsoleCubit>();
        return SerialGroup(
          title: t.mqtt.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SerialFieldRow(
                label: t.mqtt.scheme,
                child: SerialDropdown<MqttScheme>(
                  value: state.scheme,
                  items: const [
                    (value: MqttScheme.mqtt, label: 'mqtt'),
                    (value: MqttScheme.mqtts, label: 'mqtts'),
                    (value: MqttScheme.ws, label: 'ws'),
                    (value: MqttScheme.wss, label: 'wss'),
                  ],
                  onChanged: (value) => cubit.patch(scheme: value),
                ),
              ),
              SerialFieldRow(
                label: t.mqtt.host,
                child: MqttCommitField(
                  value: state.host,
                  onCommit: (value) => cubit.patch(host: value),
                ),
              ),
              SerialFieldRow(
                label: t.mqtt.port,
                child: MqttCommitField(
                  value: '${state.port}',
                  numeric: true,
                  onCommit: (value) => cubit.patch(port: value),
                ),
              ),
              if (state.scheme.webSocket)
                SerialFieldRow(
                  label: t.mqtt.path,
                  child: MqttCommitField(
                    value: state.wsPath,
                    onCommit: (value) => cubit.patch(wsPath: value),
                  ),
                ),
              SerialButton(
                label: state.connecting
                    ? t.mqtt.connecting
                    : state.connected
                    ? t.mqtt.disconnect
                    : t.mqtt.connect,
                primary: !state.connected,
                expand: true,
                height: SerialMetrics.openButton,
                leading: SerialLamp(
                  color: state.connected ? palette.on : palette.off,
                ),
                onPressed: state.connecting ? null : cubit.toggleConnect,
              ),
              SerialSectionLabel(t.mqtt.section.session),
              SerialFieldRow(
                label: t.mqtt.version,
                child: SerialDropdown<MqttVersion>(
                  value: state.version,
                  items: const [
                    (value: MqttVersion.v311, label: '3.1.1'),
                    (value: MqttVersion.v5, label: '5.0'),
                  ],
                  onChanged: (value) => cubit.patch(version: value),
                ),
              ),
              SerialFieldRow(
                label: t.mqtt.clientId,
                child: MqttCommitField(
                  value: state.clientId,
                  onCommit: (value) => cubit.patch(clientId: value),
                ),
              ),
              SerialFieldRow(
                label: t.mqtt.username,
                child: MqttCommitField(
                  value: state.username,
                  onCommit: (value) => cubit.patch(username: value),
                ),
              ),
              SerialFieldRow(
                label: t.mqtt.password,
                child: MqttCommitField(
                  value: state.password,
                  onCommit: (value) => cubit.patch(password: value),
                ),
              ),
              SerialFieldRow(
                label: t.mqtt.keepAlive,
                child: MqttCommitField(
                  value: '${state.keepAlive}',
                  numeric: true,
                  onCommit: (value) => cubit.patch(keepAlive: value),
                ),
              ),
              if (state.version == MqttVersion.v5)
                SerialFieldRow(
                  label: t.mqtt.sessionExpiry,
                  child: MqttCommitField(
                    value: '${state.sessionExpiry}',
                    numeric: true,
                    onCommit: (value) => cubit.patch(sessionExpiry: value),
                  ),
                ),
              SerialCheck(
                label: t.mqtt.cleanStart,
                value: state.cleanStart,
                onChanged: (value) => cubit.patch(cleanStart: value),
              ),
              SerialCheck(
                label: t.mqtt.autoReconnect,
                value: state.autoReconnect,
                onChanged: (value) => cubit.patch(autoReconnect: value),
              ),
              if (state.scheme.showsCertificates) ...[
                SerialSectionLabel(t.mqtt.section.tls),
                _FileRow(
                  label: t.mqtt.ca,
                  value: mqttFileLabel(t, state.caFile),
                  onPick: cubit.pickCa,
                ),
                _FileRow(
                  label: t.mqtt.cert,
                  value: mqttFileLabel(t, state.clientCert),
                  onPick: cubit.pickCert,
                ),
                _FileRow(
                  label: t.mqtt.key,
                  value: mqttFileLabel(t, state.clientKey),
                  onPick: cubit.pickKey,
                ),
              ],
              SerialSectionLabel(t.mqtt.section.will),
              SerialFieldRow(
                label: t.mqtt.willTopic,
                child: MqttCommitField(
                  value: state.willTopic,
                  onCommit: (value) => cubit.patch(willTopic: value),
                ),
              ),
              SerialFieldRow(
                label: t.mqtt.willPayload,
                child: MqttCommitField(
                  value: state.willPayload,
                  onCommit: (value) => cubit.patch(willPayload: value),
                ),
              ),
              SerialFieldRow(
                label: t.mqtt.willQos,
                child: SerialDropdown<int>(
                  value: state.willQos,
                  items: const [
                    (value: 0, label: '0'),
                    (value: 1, label: '1'),
                    (value: 2, label: '2'),
                  ],
                  onChanged: (value) => cubit.patch(willQos: value),
                ),
              ),
              SerialCheck(
                label: t.mqtt.willRetain,
                value: state.willRetain,
                onChanged: (value) => cubit.patch(willRetain: value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final String value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return SerialFieldRow(
      label: label,
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(
                Theme.of(context).colorScheme,
              ).copyWith(color: SerialPalette.of(context).muted),
            ),
          ),
          SerialButton(
            label: Translations.of(context).mqtt.pick,
            small: true,
            onPressed: onPick,
          ),
        ],
      ),
    );
  }
}

class MqttCommitField extends StatefulWidget {
  const MqttCommitField({
    super.key,
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
  State<MqttCommitField> createState() => MqttCommitFieldState();
}

class MqttCommitFieldState extends State<MqttCommitField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(covariant MqttCommitField oldWidget) {
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
