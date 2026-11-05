import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/data/serial_stamp.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';
import '../../serial/widget/serial_editors.dart';
import '../cubit/mqtt_console_cubit.dart';
import '../cubit/mqtt_console_state.dart';
import '../model/mqtt_models.dart';
import 'mqtt_script_panel.dart';

class MqttToolsPanel extends StatelessWidget {
  const MqttToolsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      buildWhen: (a, b) => a.toolTab != b.toolTab,
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
                    for (final tab in const [
                      MqttToolTab.subs,
                      MqttToolTab.quick,
                      MqttToolTab.history,
                    ])
                      Expanded(
                        child: _TabButton(
                          tab: tab,
                          active: state.toolTab == tab,
                        ),
                      ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(width: 1, height: 18, color: palette.line),
                    const SizedBox(width: AppSpacing.xs),
                    _TabButton(
                      tab: MqttToolTab.script,
                      active: state.toolTab == MqttToolTab.script,
                      padded: true,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: palette.line),
              Expanded(
                child: switch (state.toolTab) {
                  MqttToolTab.subs => const _SubTab(),
                  MqttToolTab.quick => const _QuickTab(),
                  MqttToolTab.history => const _HistoryTab(),
                  MqttToolTab.script => const MqttScriptPanel(),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.active,
    this.padded = false,
  });

  final MqttToolTab tab;
  final bool active;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final t = Translations.of(context).mqtt.tab;
    final label = switch (tab) {
      MqttToolTab.subs => t.subs,
      MqttToolTab.quick => t.quick,
      MqttToolTab.history => t.history,
      MqttToolTab.script => t.script,
    };
    return InkWell(
      onTap: () => context.read<MqttConsoleCubit>().setTab(tab),
      child: Container(
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
}

class _SubTab extends StatelessWidget {
  const _SubTab();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      buildWhen: (a, b) => a.subs != b.subs,
      builder: (context, state) {
        final cubit = context.read<MqttConsoleCubit>();
        return Column(
          children: [
            SerialToolBar(
              note: t.mqtt.subs.note,
              actions: [
                SerialButton(
                  label: t.common.add,
                  small: true,
                  onPressed: () => _addSub(context, cubit),
                ),
              ],
            ),
            Expanded(
              child: state.subs.isEmpty
                  ? _Explain(t.mqtt.subs.empty)
                  : ListView(
                      children: [
                        for (final item in state.subs)
                          SerialItemRow(
                            title: item.topic,
                            detail: 'QoS ${item.qos}',
                            trailing: [
                              SerialButton(
                                label: item.subscribed
                                    ? t.mqtt.subs.unsubscribe
                                    : t.mqtt.subs.subscribe,
                                small: true,
                                primary: !item.subscribed,
                                danger: item.subscribed,
                                onPressed: () =>
                                    cubit.toggleSubscription(item.id),
                              ),
                            ],
                            menu: [
                              SerialMenuAction(
                                label: t.common.edit,
                                onTap: () => _editSub(context, cubit, item),
                              ),
                              SerialMenuAction(
                                label: t.common.delete,
                                danger: true,
                                onTap: () => showSerialDelete(
                                  context,
                                  message: t.mqtt.subs.delete(
                                    topic: item.topic,
                                  ),
                                  onDelete: () =>
                                      cubit.deleteSubscription(item.id),
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

Future<void> _addSub(BuildContext context, MqttConsoleCubit cubit) async {
  final draft = await showSerialDialog<_SubDraft>(
    context: context,
    builder: (dialogContext) => const _SubForm(),
  );
  if (draft == null) return;
  await cubit.subscribe(topic: draft.topic, qos: draft.qos);
}

Future<void> _editSub(
  BuildContext context,
  MqttConsoleCubit cubit,
  MqttSubscription item,
) async {
  final draft = await showSerialDialog<_SubDraft>(
    context: context,
    builder: (dialogContext) => _SubForm(initial: item),
  );
  if (draft == null) return;
  await cubit.updateSubscription(item.id, topic: draft.topic, qos: draft.qos);
}

class _QuickTab extends StatelessWidget {
  const _QuickTab();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      buildWhen: (a, b) =>
          a.pubTopics != b.pubTopics || a.pubTopic != b.pubTopic,
      builder: (context, state) {
        final cubit = context.read<MqttConsoleCubit>();
        final palette = SerialPalette.of(context);
        return Column(
          children: [
            SerialToolBar(
              note: t.mqtt.pubs.title,
              actions: [
                SerialButton(
                  label: t.common.add,
                  small: true,
                  onPressed: () => _addTopic(context, cubit),
                ),
              ],
            ),
            Expanded(
              child: state.pubTopics.isEmpty
                  ? _Explain(t.mqtt.pubs.empty)
                  : ListView(
                      children: [
                        for (final item in state.pubTopics)
                          SerialItemRow(
                            color: item.topic == state.pubTopic
                                ? palette.hover
                                : null,
                            leading: SerialButton(
                              label: t.mqtt.pubs.fill,
                              small: true,
                              onPressed: () => cubit.fillTopic(item.id),
                            ),
                            title: item.name,
                            detail: item.topic,
                            menu: [
                              SerialMenuAction(
                                label: t.common.delete,
                                danger: true,
                                onTap: () => showSerialDelete(
                                  context,
                                  message: t.mqtt.pubs.deleteBody(
                                    name: item.name,
                                    topic: item.topic,
                                  ),
                                  onDelete: () =>
                                      cubit.deletePublishTopic(item.id),
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
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      buildWhen: (a, b) => a.history != b.history,
      builder: (context, state) {
        final cubit = context.read<MqttConsoleCubit>();
        return Column(
          children: [
            SerialToolBar(
              note: t.mqtt.history.note,
              actions: [
                SerialButton(
                  label: t.mqtt.history.clear,
                  small: true,
                  onPressed: state.history.isEmpty
                      ? null
                      : () => showSerialDelete(
                          context,
                          message: t.mqtt.history.deleteAll(
                            count: state.history.length,
                          ),
                          onDelete: cubit.clearHistory,
                        ),
                ),
              ],
            ),
            Expanded(
              child: state.history.isEmpty
                  ? _Explain(t.mqtt.history.empty)
                  : ListView(
                      children: [
                        for (var i = 0; i < state.history.length; i++)
                          SerialItemRow(
                            leading: SerialButton(
                              label: state.history[i].time == null
                                  ? '--:--:--'
                                  : clockStamp(
                                      state.history[i].time!,
                                    ).substring(0, 8),
                              small: true,
                              onPressed: () => cubit.resendHistory(i),
                            ),
                            title: state.history[i].payload,
                            monoTitle: true,
                            detail: _historyDetail(t, state.history[i]),
                            trailing: [
                              SerialLinkButton(
                                label: t.mqtt.history.fill,
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
      },
    );
  }
}

String _historyDetail(Translations t, MqttHistoryEntry item) {
  final retain = item.retain ? ' · ${t.mqtt.compose.retain}' : '';
  return '${item.topic} · QoS ${item.qos}$retain';
}

class _Explain extends StatelessWidget {
  const _Explain(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        text,
        style: AppTextStyles.caption(
          Theme.of(context).colorScheme,
        ).copyWith(color: SerialPalette.of(context).muted),
      ),
    );
  }
}

Future<void> _addTopic(BuildContext context, MqttConsoleCubit cubit) async {
  final draft = await showSerialDialog<_TopicDraft>(
    context: context,
    builder: (dialogContext) => const _TopicForm(),
  );
  if (draft == null) return;
  cubit.addPublishTopic(name: draft.name, topic: draft.topic);
}

class _SubDraft {
  const _SubDraft({required this.topic, required this.qos});

  final String topic;
  final int qos;
}

class _SubForm extends StatefulWidget {
  const _SubForm({this.initial});

  final MqttSubscription? initial;

  @override
  State<_SubForm> createState() => _SubFormState();
}

class _SubFormState extends State<_SubForm> {
  late final TextEditingController _topic = TextEditingController(
    text: widget.initial?.topic ?? '',
  );
  late var _qos = widget.initial?.qos ?? 0;
  var _error = '';

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  void _save() {
    final topic = _topic.text.trim();
    if (topic.isEmpty) {
      setState(() => _error = Translations.of(context).mqtt.subs.needTopic);
      return;
    }
    Navigator.pop(context, _SubDraft(topic: topic, qos: _qos));
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final editing = widget.initial != null;
    return SerialDialogFrame(
      title: editing ? t.mqtt.subs.editTitle : t.mqtt.subs.dialogTitle,
      body: Column(
        children: [
          _Row(
            label: t.mqtt.pubs.topic,
            child: SerialField(controller: _topic, mono: true),
          ),
          _Row(
            label: t.mqtt.subs.qos,
            child: SerialDropdown<int>(
              value: _qos,
              height: 28,
              items: const [
                (value: 0, label: '0'),
                (value: 1, label: '1'),
                (value: 2, label: '2'),
              ],
              onChanged: (value) => setState(() => _qos = value),
            ),
          ),
          SerialDialogError(message: _error),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        SerialButton(
          label: editing ? t.common.save : t.mqtt.subs.subscribe,
          primary: true,
          onPressed: _save,
        ),
      ],
    );
  }
}

class _TopicDraft {
  const _TopicDraft({required this.name, required this.topic});

  final String name;
  final String topic;
}

class _TopicForm extends StatefulWidget {
  const _TopicForm();

  @override
  State<_TopicForm> createState() => _TopicFormState();
}

class _TopicFormState extends State<_TopicForm> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _topic = TextEditingController();
  var _error = '';

  @override
  void dispose() {
    _name.dispose();
    _topic.dispose();
    super.dispose();
  }

  void _save() {
    final t = Translations.of(context).mqtt.pubs;
    final name = _name.text.trim();
    final topic = _topic.text.trim();
    if (name.isEmpty) {
      setState(() => _error = t.needName);
      return;
    }
    if (topic.isEmpty) {
      setState(() => _error = t.needTopic);
      return;
    }
    Navigator.pop(context, _TopicDraft(name: name, topic: topic));
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return SerialDialogFrame(
      title: t.mqtt.pubs.newTitle,
      body: Column(
        children: [
          _Row(
            label: t.mqtt.pubs.name,
            child: SerialField(controller: _name),
          ),
          _Row(
            label: t.mqtt.pubs.topic,
            child: SerialField(controller: _topic, mono: true),
          ),
          SerialDialogError(message: _error),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        SerialButton(label: t.common.save, primary: true, onPressed: _save),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(
        children: [
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: AppTextStyles.caption(
                Theme.of(context).colorScheme,
              ).copyWith(color: palette.muted, fontSize: 13),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(child: child),
        ],
      ),
    );
  }
}
