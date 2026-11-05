import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../i18n/i18n.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';

Future<QuickCommand?> showBleQuickEditor(
  BuildContext context, {
  QuickCommand? initial,
}) {
  return showSerialDialog<QuickCommand>(
    context: context,
    builder: (dialogContext) => _QuickForm(initial: initial),
  );
}

class _QuickForm extends StatefulWidget {
  const _QuickForm({this.initial});

  final QuickCommand? initial;

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
  late String _key = widget.initial?.key ?? '';

  @override
  void dispose() {
    _name.dispose();
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return SerialDialogFrame(
      title: t.ble.dialog.quickTitle,
      body: Column(
        children: [
          SerialField(controller: _name, hint: t.ble.dialog.name),
          const SizedBox(height: AppSpacing.sm),
          SerialField(controller: _data, hint: t.ble.dialog.data, mono: true),
          const SizedBox(height: AppSpacing.sm),
          SerialDropdown<String>(
            value: _key,
            items: [
              (value: '', label: t.ble.dialog.key),
              for (final key in fnKeys) (value: key, label: key),
            ],
            onChanged: (value) => setState(() => _key = value),
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
              QuickCommand(
                id: widget.initial?.id ?? newSerialId('q'),
                name: _name.text.trim().isEmpty ? _data.text : _name.text.trim(),
                data: _data.text,
                format: DataFormat.hex,
                key: _key,
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<ReplyRule?> showBleRuleEditor(
  BuildContext context, {
  ReplyRule? initial,
}) {
  return showSerialDialog<ReplyRule>(
    context: context,
    builder: (dialogContext) => _RuleForm(initial: initial),
  );
}

class _RuleForm extends StatefulWidget {
  const _RuleForm({this.initial});

  final ReplyRule? initial;

  @override
  State<_RuleForm> createState() => _RuleFormState();
}

class _RuleFormState extends State<_RuleForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late final TextEditingController _pattern = TextEditingController(
    text: widget.initial?.pattern ?? '',
  );
  late final TextEditingController _reply = TextEditingController(
    text: widget.initial?.replies.firstOrNull?.data ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _pattern.dispose();
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return SerialDialogFrame(
      title: t.ble.dialog.ruleTitle,
      body: Column(
        children: [
          SerialField(controller: _name, hint: t.ble.dialog.name),
          const SizedBox(height: AppSpacing.sm),
          SerialField(
            controller: _pattern,
            hint: t.ble.dialog.pattern,
            mono: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          SerialField(controller: _reply, hint: t.ble.dialog.data, mono: true),
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
              ReplyRule(
                id: widget.initial?.id ?? newSerialId('r'),
                name: _name.text.trim().isEmpty
                    ? _pattern.text
                    : _name.text.trim(),
                match: MatchMode.prefix,
                pattern: _pattern.text,
                enabled: widget.initial?.enabled ?? true,
                hits: widget.initial?.hits ?? 0,
                replies: [ReplyStep(data: _reply.text, delayMs: 0)],
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<BatchJob?> showBleBatchEditor(
  BuildContext context, {
  BatchJob? initial,
}) {
  return showSerialDialog<BatchJob>(
    context: context,
    builder: (dialogContext) => _BatchForm(initial: initial),
  );
}

class _BatchForm extends StatefulWidget {
  const _BatchForm({this.initial});

  final BatchJob? initial;

  @override
  State<_BatchForm> createState() => _BatchFormState();
}

class _BatchFormState extends State<_BatchForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late final TextEditingController _data = TextEditingController(
    text: widget.initial?.steps.map((s) => s.data).join('\n') ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return SerialDialogFrame(
      title: t.ble.dialog.batchTitle,
      body: Column(
        children: [
          SerialField(controller: _name, hint: t.ble.dialog.name),
          const SizedBox(height: AppSpacing.sm),
          SerialField(
            controller: _data,
            hint: t.ble.dialog.data,
            mono: true,
            maxLines: 6,
            height: 140,
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
            final steps = [
              for (final line in _data.text.split('\n'))
                if (line.trim().isNotEmpty)
                  BatchStep(data: line.trim(), delayMs: 0),
            ];
            Navigator.pop(
              context,
              BatchJob(
                id: widget.initial?.id ?? newSerialId('b'),
                name: _name.text.trim().isEmpty ? 'batch' : _name.text.trim(),
                repeat: 1,
                stopOnFail: true,
                steps: steps,
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<LuaScript?> showBleScriptEditor(
  BuildContext context, {
  LuaScript? initial,
}) {
  return showSerialDialog<LuaScript>(
    context: context,
    builder: (dialogContext) => _ScriptForm(initial: initial),
  );
}

class _ScriptForm extends StatefulWidget {
  const _ScriptForm({this.initial});

  final LuaScript? initial;

  @override
  State<_ScriptForm> createState() => _ScriptFormState();
}

class _ScriptFormState extends State<_ScriptForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? 'script.lua',
  );
  late final TextEditingController _code = TextEditingController(
    text: widget.initial?.code ?? LuaScript.template,
  );

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return SerialDialogFrame(
      title: t.ble.dialog.scriptTitle,
      body: Column(
        children: [
          SerialField(controller: _name, hint: t.ble.dialog.name),
          const SizedBox(height: AppSpacing.sm),
          SerialField(
            controller: _code,
            hint: t.ble.dialog.code,
            mono: true,
            maxLines: 12,
            height: 240,
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
              LuaScript(
                id: widget.initial?.id ?? newSerialId('s'),
                name: _name.text.trim().isEmpty
                    ? 'script.lua'
                    : _name.text.trim(),
                code: _code.text,
                enabled: widget.initial?.enabled ?? false,
              ),
            );
          },
        ),
      ],
    );
  }
}
