import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';
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
      children: const [
        _ConnGroup(),
        SizedBox(height: AppSpacing.xs + 2),
        _SubGroup(),
        SizedBox(height: AppSpacing.xs + 2),
        _PubGroup(),
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
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      builder: (context, state) {
        final cubit = context.read<MqttConsoleCubit>();
        return SerialGroup(
          title: t.mqtt.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Field(
                label: t.mqtt.host,
                child: _CommitField(
                  value: state.host,
                  onCommit: (value) => cubit.patch(host: value),
                ),
              ),
              _Field(
                label: t.mqtt.port,
                child: _CommitField(
                  value: '${state.port}',
                  numeric: true,
                  onCommit: (value) => cubit.patch(port: value),
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
              SerialLinkButton(
                label: state.settingsOpen ? t.mqtt.collapse : t.mqtt.expand,
                onPressed: () => cubit.patch(settingsOpen: !state.settingsOpen),
              ),
              if (state.settingsOpen) ...[
                const SizedBox(height: AppSpacing.xs),
                _Field(
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
                _Field(
                  label: t.mqtt.clientId,
                  child: _CommitField(
                    value: state.clientId,
                    onCommit: (value) => cubit.patch(clientId: value),
                  ),
                ),
                _Field(
                  label: t.mqtt.username,
                  child: _CommitField(
                    value: state.username,
                    onCommit: (value) => cubit.patch(username: value),
                  ),
                ),
                _Field(
                  label: t.mqtt.password,
                  child: _CommitField(
                    value: state.password,
                    onCommit: (value) => cubit.patch(password: value),
                  ),
                ),
                SerialCheck(
                  label: t.mqtt.tls,
                  value: state.tls,
                  onChanged: (value) => cubit.patch(tls: value),
                ),
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
                _Field(
                  label: t.mqtt.keepAlive,
                  child: _CommitField(
                    value: '${state.keepAlive}',
                    numeric: true,
                    onCommit: (value) => cubit.patch(keepAlive: value),
                  ),
                ),
                if (state.version == MqttVersion.v5)
                  _Field(
                    label: t.mqtt.sessionExpiry,
                    child: _CommitField(
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
                _Field(
                  label: t.mqtt.willTopic,
                  child: _CommitField(
                    value: state.willTopic,
                    onCommit: (value) => cubit.patch(willTopic: value),
                  ),
                ),
                _Field(
                  label: t.mqtt.willPayload,
                  child: _CommitField(
                    value: state.willPayload,
                    onCommit: (value) => cubit.patch(willPayload: value),
                  ),
                ),
                _Field(
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
            ],
          ),
        );
      },
    );
  }
}

class _SubGroup extends StatelessWidget {
  const _SubGroup();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      builder: (context, state) {
        final cubit = context.read<MqttConsoleCubit>();
        return SerialGroup(
          title: t.mqtt.subs.title,
          trailing: Text(
            '${state.subs.length}',
            style: AppTextStyles.caption(
              Theme.of(context).colorScheme,
            ).copyWith(color: palette.muted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.subs.isEmpty)
                Text(
                  t.mqtt.subs.empty,
                  style: AppTextStyles.caption(
                    Theme.of(context).colorScheme,
                  ).copyWith(color: palette.muted),
                ),
              for (final item in state.subs)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.topic,
                              style: AppTextStyles.caption(
                                Theme.of(context).colorScheme,
                              ).copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'QoS ${item.qos}',
                              style: AppTextStyles.caption(
                                Theme.of(context).colorScheme,
                              ).copyWith(color: palette.muted),
                            ),
                          ],
                        ),
                      ),
                      SerialButton(
                        label: t.mqtt.subs.unsubscribe,
                        small: true,
                        danger: true,
                        onPressed: () => cubit.unsubscribe(item.id),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: _CommitField(
                      value: state.draftSubTopic,
                      hint: t.mqtt.subs.topic,
                      onCommit: (value) => cubit.patch(draftSubTopic: value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 56,
                    child: SerialDropdown<int>(
                      value: state.draftSubQos,
                      items: const [
                        (value: 0, label: '0'),
                        (value: 1, label: '1'),
                        (value: 2, label: '2'),
                      ],
                      onChanged: (value) => cubit.patch(draftSubQos: value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SerialButton(
                    label: t.mqtt.subs.subscribe,
                    small: true,
                    primary: true,
                    onPressed: cubit.subscribe,
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

class _PubGroup extends StatelessWidget {
  const _PubGroup();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      builder: (context, state) {
        final cubit = context.read<MqttConsoleCubit>();
        return SerialGroup(
          title: t.mqtt.pubs.title,
          trailing: Text(
            '${state.pubTopics.length}',
            style: AppTextStyles.caption(
              Theme.of(context).colorScheme,
            ).copyWith(color: palette.muted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in state.pubTopics)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: item.topic == state.pubTopic
                          ? palette.hover
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        SerialMetrics.controlRadius,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => cubit.fillTopic(item.id),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTextStyles.caption(
                                      Theme.of(context).colorScheme,
                                    ).copyWith(
                                      color: palette.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    item.topic,
                                    style: AppTextStyles.mono(
                                      Theme.of(context).colorScheme,
                                      fontSize: 12,
                                      color: palette.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SerialButton(
                            label: t.mqtt.pubs.fill,
                            small: true,
                            onPressed: () => cubit.fillTopic(item.id),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          SerialButton(
                            label: t.mqtt.pubs.delete,
                            small: true,
                            danger: true,
                            onPressed: () =>
                                _confirmDelete(context, cubit, item),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: _CommitField(
                      value: state.draftPubName,
                      hint: t.mqtt.pubs.name,
                      onCommit: (value) => cubit.patch(draftPubName: value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _CommitField(
                      value: state.draftPubTopic,
                      hint: t.mqtt.pubs.topic,
                      onCommit: (value) => cubit.patch(draftPubTopic: value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SerialButton(
                    label: t.mqtt.pubs.add,
                    small: true,
                    primary: true,
                    onPressed: cubit.addPublishTopic,
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

Future<void> _confirmDelete(
  BuildContext context,
  MqttConsoleCubit cubit,
  MqttPublishTopic item,
) async {
  final t = Translations.of(context);
  final ok = await showSerialDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return SerialDialogFrame(
        title: t.mqtt.pubs.deleteTitle,
        body: Text(t.mqtt.pubs.deleteBody(name: item.name, topic: item.topic)),
        actions: [
          SerialButton(
            label: t.common.cancel,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          SerialButton(
            label: t.common.delete,
            primary: true,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      );
    },
  );
  if (ok == true) cubit.deletePublishTopic(item.id);
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
    return _Field(
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
            width: SerialMetrics.labelCol + 10,
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
