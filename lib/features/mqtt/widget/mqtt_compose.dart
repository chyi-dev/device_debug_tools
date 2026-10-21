import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../cubit/mqtt_console_cubit.dart';
import '../cubit/mqtt_console_state.dart';

class MqttCompose extends StatefulWidget {
  const MqttCompose({super.key});

  @override
  State<MqttCompose> createState() => _MqttComposeState();
}

class _MqttComposeState extends State<MqttCompose> {
  late final TextEditingController _topic = TextEditingController();
  late final TextEditingController _payload = TextEditingController();

  @override
  void dispose() {
    _topic.dispose();
    _payload.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocConsumer<MqttConsoleCubit, MqttConsoleState>(
      listenWhen: (a, b) => a.pubTopic != b.pubTopic || a.payload != b.payload,
      listener: (context, state) {
        if (_topic.text != state.pubTopic) _topic.text = state.pubTopic;
        if (_payload.text != state.payload) _payload.text = state.payload;
      },
      builder: (context, state) {
        if (_topic.text.isEmpty && state.pubTopic.isNotEmpty) {
          _topic.text = state.pubTopic;
        }
        if (_payload.text.isEmpty && state.payload.isNotEmpty) {
          _payload.text = state.payload;
        }
        final cubit = context.read<MqttConsoleCubit>();
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border.all(color: palette.line),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      t.mqtt.compose.to,
                      style: AppTextStyles.caption(
                        cs,
                      ).copyWith(color: palette.muted),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SerialField(
                        controller: _topic,
                        height: SerialMetrics.controlSm,
                        onChanged: (value) => cubit.patch(pubTopic: value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 64,
                      child: SerialDropdown<int>(
                        value: state.pubQos,
                        items: const [
                          (value: 0, label: '0'),
                          (value: 1, label: '1'),
                          (value: 2, label: '2'),
                        ],
                        onChanged: (value) => cubit.patch(pubQos: value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SerialCheck(
                      label: t.mqtt.compose.retain,
                      value: state.pubRetain,
                      onChanged: (value) => cubit.patch(pubRetain: value),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: SerialMetrics.sendHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.enter &&
                              HardwareKeyboard.instance.isControlPressed) {
                            cubit.publish();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: _payload,
                          expands: true,
                          maxLines: null,
                          onChanged: (value) => cubit.patch(payload: value),
                          style: AppTextStyles.mono(
                            cs,
                            fontSize: 15,
                            height: 1.5,
                            color: palette.text,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: palette.field,
                            hintText: t.mqtt.compose.payload,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(AppSpacing.sm),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: SerialMetrics.sendSide,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SerialButton(
                              label: t.mqtt.compose.publish,
                              primary: true,
                              expand: true,
                              onPressed: cubit.publish,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SerialButton(
                              label: t.mqtt.compose.clear,
                              expand: true,
                              onPressed: () => cubit.patch(payload: ''),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.line2)),
                ),
                child: Row(
                  children: [
                    Text(
                      t.mqtt.compose.bytes(
                        count: utf8.encode(state.payload).length,
                      ),
                      style: AppTextStyles.caption(
                        cs,
                      ).copyWith(color: palette.muted),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        '${state.pubTopic} · QoS ${state.pubQos}${state.pubRetain ? ' · Retain' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(
                          cs,
                        ).copyWith(color: palette.muted),
                      ),
                    ),
                    Text(
                      t.mqtt.compose.ctrlEnter,
                      style: AppTextStyles.caption(
                        cs,
                      ).copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
