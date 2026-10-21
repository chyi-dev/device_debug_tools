import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';
import '../cubit/mqtt_console_cubit.dart';
import '../cubit/mqtt_console_state.dart';
import '../model/mqtt_models.dart';

class MqttToolsPanel extends StatelessWidget {
  const MqttToolsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  t.serial.tab.quick,
                  style: AppTextStyles.caption(
                    Theme.of(context).colorScheme,
                  ).copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(child: _QuickList()),
        ],
      ),
    );
  }
}

class _QuickList extends StatelessWidget {
  const _QuickList();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      buildWhen: (a, b) =>
          a.quick != b.quick ||
          a.pubTopic != b.pubTopic ||
          a.pubQos != b.pubQos ||
          a.pubRetain != b.pubRetain,
      builder: (context, state) {
        final cubit = context.read<MqttConsoleCubit>();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.mqtt.quick.bar,
                      style: AppTextStyles.caption(
                        Theme.of(context).colorScheme,
                      ).copyWith(color: palette.muted),
                    ),
                  ),
                  SerialButton(
                    label: t.common.add,
                    small: true,
                    onPressed: () async {
                      final item = await _editQuick(context);
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          SerialButton(
                            label: t.mqtt.quick.publish,
                            small: true,
                            primary: true,
                            onPressed: () => cubit.publishQuick(item.id),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.name} ${item.key}',
                                  style: AppTextStyles.caption(
                                    Theme.of(context).colorScheme,
                                  ).copyWith(
                                    color: palette.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  item.data,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.mono(
                                    Theme.of(context).colorScheme,
                                    fontSize: 12,
                                    color: palette.muted,
                                  ),
                                ),
                                Text(
                                  item.inherit
                                      ? t.mqtt.quick.inheritLabel(
                                          topic: state.pubTopic,
                                          qos: state.pubQos,
                                        )
                                      : '${item.topic} · QoS ${item.qos}',
                                  style: AppTextStyles.caption(
                                    Theme.of(context).colorScheme,
                                  ).copyWith(color: palette.muted),
                                ),
                              ],
                            ),
                          ),
                          SerialLinkButton(
                            label: t.mqtt.quick.kOverride,
                            onPressed: () async {
                              final next = await _editQuick(
                                context,
                                initial: item,
                              );
                              if (next != null) cubit.saveQuick(next);
                            },
                          ),
                        ],
                      ),
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

Future<MqttQuickCommand?> _editQuick(
  BuildContext context, {
  MqttQuickCommand? initial,
}) {
  return showSerialDialog<MqttQuickCommand>(
    context: context,
    builder: (dialogContext) => _QuickForm(initial: initial),
  );
}

class _QuickForm extends StatefulWidget {
  const _QuickForm({this.initial});

  final MqttQuickCommand? initial;

  @override
  State<_QuickForm> createState() => _QuickFormState();
}

class _QuickFormState extends State<_QuickForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late final TextEditingController _data = TextEditingController(
    text: widget.initial?.data ?? '',
  );
  late final TextEditingController _topic = TextEditingController(
    text: widget.initial?.topic ?? '',
  );
  late bool _inherit = widget.initial?.inherit ?? true;
  late int _qos = widget.initial?.qos ?? 0;
  late bool _retain = widget.initial?.retain ?? false;
  late String _key = widget.initial?.key ?? '';

  @override
  void dispose() {
    _name.dispose();
    _data.dispose();
    _topic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return SerialDialogFrame(
      title: t.mqtt.quick.dialogTitle,
      body: Column(
        children: [
          SerialField(controller: _name, hint: t.mqtt.pubs.name),
          const SizedBox(height: AppSpacing.sm),
          SerialField(controller: _data, hint: t.mqtt.compose.payload, mono: true),
          const SizedBox(height: AppSpacing.sm),
          SerialDropdown<String>(
            value: _key,
            items: [
              (value: '', label: t.ble.dialog.key),
              for (final key in fnKeys) (value: key, label: key),
            ],
            onChanged: (value) => setState(() => _key = value),
          ),
          SerialCheck(
            label: t.mqtt.quick.inherit,
            value: _inherit,
            onChanged: (value) => setState(() => _inherit = value),
          ),
          if (!_inherit)
            SerialField(controller: _topic, hint: t.mqtt.pubs.topic),
          const SizedBox(height: AppSpacing.sm),
          SerialDropdown<int>(
            value: _qos,
            items: const [
              (value: 0, label: '0'),
              (value: 1, label: '1'),
              (value: 2, label: '2'),
            ],
            onChanged: (value) => setState(() => _qos = value),
          ),
          SerialCheck(
            label: t.mqtt.compose.retain,
            value: _retain,
            onChanged: (value) => setState(() => _retain = value),
          ),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        SerialButton(
          label: t.common.save,
          primary: true,
          onPressed: () {
            Navigator.pop(
              context,
              MqttQuickCommand(
                id: widget.initial?.id ?? newSerialId('q'),
                name: _name.text.trim().isEmpty ? _data.text : _name.text.trim(),
                data: _data.text,
                key: _key,
                inherit: _inherit,
                topic: _topic.text.trim(),
                qos: _qos,
                retain: _retain,
              ),
            );
          },
        ),
      ],
    );
  }
}
