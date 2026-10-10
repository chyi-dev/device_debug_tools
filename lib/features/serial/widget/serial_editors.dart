import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/serial_console_cubit.dart';
import '../data/serial_bytes.dart';
import '../model/reply_lessons.dart';
import '../model/serial_models.dart';
import '../serial_metrics.dart';
import 'serial_chrome.dart';
import 'serial_dialog.dart';
import 'serial_l10n.dart';
import 'serial_reply_tutor.dart';

/// [folderId] 为新增指令时预选的文件夹；编辑已有指令时取其所在文件夹。
Future<void> showQuickEditor(
  BuildContext context, {
  QuickCommand? existing,
  String? folderId,
}) {
  final cubit = context.read<SerialConsoleCubit>();
  final quick = cubit.state.quick;
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: _QuickEditor(
        existing: existing,
        folders: quick.folders,
        folderId: existing != null ? quick.folderIdOf(existing.id) : folderId,
      ),
    ),
  );
}

Future<void> showFolderEditor(BuildContext context, {QuickFolder? existing}) {
  final cubit = context.read<SerialConsoleCubit>();
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: _FolderEditor(existing: existing),
    ),
  );
}

Future<void> showScriptRename(BuildContext context, LuaScript script) {
  final cubit = context.read<SerialConsoleCubit>();
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: _ScriptRename(script: script),
    ),
  );
}

Future<void> showRuleEditor(BuildContext context, {ReplyRule? existing}) {
  final cubit = context.read<SerialConsoleCubit>();
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: _RuleEditor(existing: existing),
    ),
  );
}

Future<void> showBatchEditor(BuildContext context, {BatchJob? existing}) {
  final cubit = context.read<SerialConsoleCubit>();
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: _BatchEditor(existing: existing),
    ),
  );
}

Future<void> showSerialDelete(
  BuildContext context, {
  required String message,
  required VoidCallback onDelete,
}) {
  final t = Translations.of(context);
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) {
      return SerialDialogFrame(
        title: t.serial.dialog.deleteTitle,
        body: Text(
          message,
          style: AppTextStyles.body(
            Theme.of(dialogContext).colorScheme,
          ).copyWith(color: SerialPalette.of(dialogContext).text),
        ),
        actions: [
          SerialButton(
            label: t.common.cancel,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          SerialButton(
            label: t.common.delete,
            primary: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDelete();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showShortcutHelp(BuildContext context) {
  final t = Translations.of(context);
  final rows = [
    (t.serial.dialog.ctrlEnter, t.serial.dialog.keySend),
    (t.serial.dialog.fKeys, t.serial.dialog.keyQuick),
    (t.serial.dialog.esc, t.serial.dialog.keyStop),
    (t.serial.kbd.ctrlS, t.serial.dialog.keySave),
    (t.serial.dialog.ctrlL, t.serial.dialog.keyClear),
    (t.serial.dialog.ctrlF, t.serial.dialog.keySearch),
    (t.serial.kbd.f12, t.serial.dialog.keyHelp),
  ];
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) {
      final palette = SerialPalette.of(dialogContext);
      final cs = Theme.of(dialogContext).colorScheme;
      return SerialDialogFrame(
        title: t.serial.dialog.keysTitle,
        body: Column(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs + 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: palette.field,
                        border: Border.all(color: palette.line),
                        borderRadius: BorderRadius.circular(
                          SerialMetrics.controlRadius,
                        ),
                      ),
                      child: Text(
                        row.$1,
                        style: AppTextStyles.mono(
                          cs,
                          fontSize: 13,
                          color: palette.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: AppTextStyles.body(
                          cs,
                        ).copyWith(color: palette.text),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          SerialButton(
            label: t.serial.dialog.know,
            primary: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      );
    },
  );
}

Future<void> showSerialAbout(BuildContext context) {
  final t = Translations.of(context);
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) {
      final palette = SerialPalette.of(dialogContext);
      final cs = Theme.of(dialogContext).colorScheme;
      return SerialDialogFrame(
        title: t.serial.dialog.aboutTitle,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.serial.dialog.aboutBody,
              style: AppTextStyles.body(cs).copyWith(color: palette.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.serial.dialog.aboutDetail,
              style: AppTextStyles.caption(
                cs,
              ).copyWith(color: palette.muted, height: 1.6),
            ),
          ],
        ),
        actions: [
          SerialButton(
            label: t.common.close,
            primary: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      );
    },
  );
}

Future<void> showFileSourceHelp(BuildContext context) {
  final t = Translations.of(context);
  final d = t.serial.dialog;
  final items = [
    d.fileRaw,
    d.fileText,
    d.fileAppend,
    d.fileWhole,
    d.filePreview(count: SerialMetrics.filePreviewBytes),
    d.fileLoop,
  ];
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) {
      final palette = SerialPalette.of(dialogContext);
      final style = AppTextStyles.body(
        Theme.of(dialogContext).colorScheme,
      ).copyWith(color: palette.text, height: 1.6);
      return SerialDialogFrame(
        title: d.fileTitle,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•', style: style.copyWith(color: palette.accent)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item, style: style)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          SerialButton(
            label: d.know,
            primary: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      );
    },
  );
}

class _QuickEditor extends StatefulWidget {
  const _QuickEditor({required this.folders, this.existing, this.folderId});

  final QuickCommand? existing;
  final List<QuickFolder> folders;
  final String? folderId;

  @override
  State<_QuickEditor> createState() => _QuickEditorState();
}

class _QuickEditorState extends State<_QuickEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _data = TextEditingController(
    text: widget.existing?.data ?? '',
  );
  late DataFormat _format = widget.existing?.format ?? DataFormat.hex;
  late String _key = widget.existing?.key ?? '';
  late String _folder = widget.folders.any((f) => f.id == widget.folderId)
      ? widget.folderId!
      : '';
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _data.dispose();
    super.dispose();
  }

  void _save() {
    final t = Translations.of(context);
    final name = _name.text.trim();
    final data = _data.text.trim();
    if (name.isEmpty) {
      setState(() => _error = t.serial.validate.needName);
      return;
    }
    if (data.isEmpty) {
      setState(() => _error = t.serial.validate.needData);
      return;
    }
    if (_format == DataFormat.hex && !SerialBytes.isHex(data)) {
      setState(() => _error = t.serial.validate.badHex);
      return;
    }
    context.read<SerialConsoleCubit>().upsertQuick(
      QuickCommand(
        id: widget.existing?.id ?? newSerialId('q'),
        name: name,
        data: data,
        format: _format,
        key: _key,
      ),
      folderId: _folder.isEmpty ? null : _folder,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final q = t.serial.quick;
    final isNew = widget.existing == null;
    return SerialDialogFrame(
      title: isNew ? q.newTitle : q.editTitle,
      body: Column(
        children: [
          _Row(
            label: q.name,
            child: SerialField(controller: _name),
          ),
          _Row(
            label: q.format,
            child: SerialDropdown<DataFormat>(
              value: _format,
              height: 28,
              items: [
                (value: DataFormat.hex, label: t.serial.mark.hex),
                (value: DataFormat.ascii, label: t.serial.mark.ascii),
              ],
              onChanged: (value) => setState(() => _format = value),
            ),
          ),
          _Row(
            label: q.data,
            child: SerialField(controller: _data, mono: true),
          ),
          _Row(
            label: q.key,
            child: SerialDropdown<String>(
              value: _key,
              height: 28,
              items: [
                (value: '', label: q.noKey),
                for (final key in fnKeys) (value: key, label: key),
              ],
              onChanged: (value) => setState(() => _key = value),
            ),
          ),
          if (widget.folders.isNotEmpty)
            _Row(
              label: q.folder,
              child: SerialDropdown<String>(
                value: _folder,
                height: 28,
                items: [
                  (value: '', label: q.root),
                  for (final folder in widget.folders)
                    (value: folder.id, label: folder.name),
                ],
                onChanged: (value) => setState(() => _folder = value),
              ),
            ),
          SerialDialogError(message: _error),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SerialButton(label: t.common.save, primary: true, onPressed: _save),
      ],
    );
  }
}

class _FolderEditor extends StatefulWidget {
  const _FolderEditor({this.existing});

  final QuickFolder? existing;

  @override
  State<_FolderEditor> createState() => _FolderEditorState();
}

class _FolderEditorState extends State<_FolderEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final t = Translations.of(context);
    final cubit = context.read<SerialConsoleCubit>();
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = t.serial.validate.needFolderName);
      return;
    }
    final duplicate = cubit.state.quick.folders.any(
      (f) => f.name == name && f.id != widget.existing?.id,
    );
    if (duplicate) {
      setState(() => _error = t.serial.validate.dupFolder);
      return;
    }
    cubit.upsertFolder(widget.existing?.id, name);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final q = t.serial.quick;
    return SerialDialogFrame(
      title: widget.existing == null ? q.folderNewTitle : q.folderEditTitle,
      body: Column(
        children: [
          _Row(
            label: q.folderName,
            child: SerialField(controller: _name),
          ),
          SerialDialogError(message: _error),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SerialButton(label: t.common.save, primary: true, onPressed: _save),
      ],
    );
  }
}

class _ScriptRename extends StatefulWidget {
  const _ScriptRename({required this.script});

  final LuaScript script;

  @override
  State<_ScriptRename> createState() => _ScriptRenameState();
}

class _ScriptRenameState extends State<_ScriptRename> {
  late final TextEditingController _name = TextEditingController(
    text: widget.script.name,
  );
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(
        () => _error = Translations.of(context).serial.validate.needName,
      );
      return;
    }
    context.read<SerialConsoleCubit>().renameScript(widget.script.id, name);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final s = t.serial.script;
    return SerialDialogFrame(
      title: s.renameTitle,
      body: Column(
        children: [
          _Row(
            label: s.name,
            child: SerialField(controller: _name, onSubmitted: (_) => _save()),
          ),
          SerialDialogError(message: _error),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SerialButton(label: t.common.save, primary: true, onPressed: _save),
      ],
    );
  }
}

class _RuleEditor extends StatefulWidget {
  const _RuleEditor({this.existing});

  final ReplyRule? existing;

  @override
  State<_RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends State<_RuleEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _pattern = TextEditingController(
    text: widget.existing?.pattern ?? '',
  );
  late MatchMode _match = widget.existing?.match ?? MatchMode.prefix;
  late MatchKind _kind = widget.existing?.kind ?? MatchKind.template;
  late DataFormat _format = widget.existing?.format ?? DataFormat.hex;
  late bool _ignoreCase = widget.existing?.ignoreCase ?? false;
  late bool _enabled = widget.existing?.enabled ?? true;
  bool _tutorOpen = false;
  String? _openLesson = 'wild';
  String? _wroteLesson;
  late final List<_Pair> _rows = [
    for (final reply
        in widget.existing?.replies ?? const [ReplyStep(data: '', delayMs: 50)])
      _Pair('${reply.delayMs}', reply.data),
  ];
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _pattern.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _save() {
    final t = Translations.of(context);
    final name = _name.text.trim();
    // ASCII 模板首尾空格可能是要匹配的内容，不裁剪。
    final pattern = _kind == MatchKind.template && _format == DataFormat.ascii
        ? _pattern.text
        : _pattern.text.trim();
    final v = t.serial.validate;
    if (name.isEmpty) {
      setState(() => _error = v.needRuleName);
      return;
    }
    int? wildcards;
    if (_kind == MatchKind.regex) {
      if (!SerialBytes.isRegex(pattern)) {
        setState(() => _error = v.badRegex);
        return;
      }
    } else {
      wildcards = SerialBytes.templateCaptureCount(pattern, _format);
      if (wildcards == null) {
        setState(
          () => _error = _format == DataFormat.hex
              ? v.badPattern
              : v.badAsciiPattern,
        );
        return;
      }
    }
    if (_rows.isEmpty) {
      setState(() => _error = v.needReply);
      return;
    }
    final replies = <ReplyStep>[];
    for (var i = 0; i < _rows.length; i++) {
      final data = _rows[i].data.text.trim();
      final delay = int.tryParse(_rows[i].delay.text.trim());
      if (!SerialBytes.isReplyHex(data)) {
        setState(() => _error = v.badReply(n: i + 1));
        return;
      }
      final ref = SerialBytes.maxCaptureRef(data);
      if (wildcards != null && ref > wildcards) {
        setState(
          () => _error = v.badCapture(n: i + 1, ref: ref, count: wildcards!),
        );
        return;
      }
      if (delay == null || delay < 0) {
        setState(() => _error = t.serial.validate.badDelay(n: i + 1));
        return;
      }
      replies.add(ReplyStep(data: data, delayMs: delay));
    }
    final previous = widget.existing;
    context.read<SerialConsoleCubit>().upsertRule(
      ReplyRule(
        id: previous?.id ?? newSerialId('r'),
        name: name,
        match: _match,
        kind: _kind,
        format: _format,
        ignoreCase: _ignoreCase,
        pattern: pattern,
        enabled: _enabled,
        hits: previous?.hits ?? 0,
        replies: replies,
      ),
    );
    Navigator.of(context).pop();
  }

  void _fillLesson(ReplyLesson lesson) {
    final name = replyLessonCopy(Translations.of(context), lesson.key).name;
    setState(() {
      _name.text = name;
      _kind = lesson.kind;
      _format = lesson.format;
      _match = lesson.match;
      _ignoreCase = lesson.ignoreCase;
      _pattern.text = lesson.pattern;
      for (final row in _rows) {
        row.dispose();
      }
      _rows
        ..clear()
        ..addAll([
          for (final reply in lesson.replies)
            _Pair('${reply.delayMs}', reply.data),
        ]);
      _enabled = true;
      _wroteLesson = lesson.key;
      _openLesson = lesson.key;
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final r = t.serial.reply;
    return SerialDialogFrame(
      title: widget.existing == null ? r.newTitle : r.editTitle,
      body: Column(
        children: [
          _Row(
            label: r.name,
            child: SerialField(controller: _name),
          ),
          _Row(
            label: r.kind,
            child: SerialDropdown<MatchKind>(
              value: _kind,
              height: 28,
              items: [
                (value: MatchKind.template, label: r.template),
                (value: MatchKind.regex, label: r.regex),
              ],
              onChanged: (value) => setState(() => _kind = value),
            ),
          ),
          _Row(
            label: r.format,
            child: SerialDropdown<DataFormat>(
              value: _format,
              height: 28,
              items: const [
                (value: DataFormat.hex, label: 'HEX'),
                (value: DataFormat.ascii, label: 'ASCII'),
              ],
              onChanged: (value) => setState(() => _format = value),
            ),
          ),
          if (_kind == MatchKind.template)
            _Row(
              label: r.match,
              child: SerialDropdown<MatchMode>(
                value: _match,
                height: 28,
                items: [
                  for (final mode in MatchMode.values)
                    (value: mode, label: matchModeLabel(t, mode)),
                ],
                onChanged: (value) => setState(() => _match = value),
              ),
            ),
          _Row(
            label: r.pattern,
            child: SerialField(
              controller: _pattern,
              mono: true,
              hint: _format == DataFormat.hex ? r.patternHint : null,
            ),
          ),
          _Row(
            label: '',
            child: Text(
              switch ((_kind, _format)) {
                (MatchKind.template, DataFormat.hex) => r.hintTemplateHex,
                (MatchKind.template, DataFormat.ascii) => r.hintTemplateAscii,
                (MatchKind.regex, DataFormat.hex) => r.hintRegexHex,
                (MatchKind.regex, DataFormat.ascii) => r.hintRegexAscii,
              },
              style: AppTextStyles.body(
                Theme.of(context).colorScheme,
              ).copyWith(color: SerialPalette.of(context).muted, fontSize: 12),
            ),
          ),
          if (_format == DataFormat.ascii)
            SerialCheck(
              label: r.ignoreCase,
              value: _ignoreCase,
              onChanged: (value) => setState(() => _ignoreCase = value),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  r.list,
                  style: AppTextStyles.body(Theme.of(context).colorScheme)
                      .copyWith(
                        color: SerialPalette.of(context).text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
              ),
              SerialButton(
                label: r.addReply,
                small: true,
                onPressed: () => setState(() => _rows.add(_Pair('50', ''))),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < _rows.length; i++)
            _LineEditor(
              index: i + 1,
              delay: _rows[i].delay,
              data: _rows[i].data,
              onRemove: () => setState(() {
                _rows.removeAt(i).dispose();
              }),
            ),
          SerialCheck(
            label: r.enable,
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          SerialDialogError(message: _error),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SerialButton(label: t.common.save, primary: true, onPressed: _save),
      ],
      titleTrailing: SerialButton(
        label: r.tutor,
        small: true,
        primary: _tutorOpen,
        onPressed: () => setState(() => _tutorOpen = !_tutorOpen),
      ),
      side: _tutorOpen
          ? ReplyTutorRail(
              openKey: _openLesson,
              wroteKey: _wroteLesson,
              onToggle: (key) => setState(() {
                _openLesson = _openLesson == key ? null : key;
              }),
              onFill: _fillLesson,
            )
          : null,
    );
  }
}

class _BatchEditor extends StatefulWidget {
  const _BatchEditor({this.existing});

  final BatchJob? existing;

  @override
  State<_BatchEditor> createState() => _BatchEditorState();
}

class _BatchEditorState extends State<_BatchEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final List<_StepRow> _rows = [
    for (final step
        in widget.existing?.steps ?? const [BatchStep(data: '', delayMs: 0)])
      _StepRow('${step.delayMs}', step.data, step.note),
  ];
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _save() {
    final t = Translations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = t.serial.validate.needTask);
      return;
    }
    if (_rows.isEmpty) {
      setState(() => _error = t.serial.validate.needStep);
      return;
    }
    final steps = <BatchStep>[];
    for (var i = 0; i < _rows.length; i++) {
      final data = _rows[i].data.text.trim();
      final delay = int.tryParse(_rows[i].delay.text.trim());
      if (!SerialBytes.isHex(data)) {
        setState(() => _error = t.serial.validate.badStep(n: i + 1));
        return;
      }
      if (delay == null || delay < 0) {
        setState(() => _error = t.serial.validate.badStepDelay(n: i + 1));
        return;
      }
      steps.add(
        BatchStep(data: data, delayMs: delay, note: _rows[i].note.text.trim()),
      );
    }
    final previous = widget.existing;
    context.read<SerialConsoleCubit>().upsertBatch(
      BatchJob(
        id: previous?.id ?? newSerialId('b'),
        name: name,
        repeat: previous?.repeat ?? 1,
        stopOnFail: previous?.stopOnFail ?? true,
        steps: steps,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final b = t.serial.batch;
    return SerialDialogFrame(
      title: widget.existing == null ? b.newTitle : b.editTitle,
      body: Column(
        children: [
          _Row(
            label: b.name,
            child: SerialField(controller: _name),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  b.sequence,
                  style: AppTextStyles.body(Theme.of(context).colorScheme)
                      .copyWith(
                        color: SerialPalette.of(context).text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
              ),
              SerialButton(
                label: b.addStep,
                small: true,
                onPressed: () =>
                    setState(() => _rows.add(_StepRow('200', '', ''))),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < _rows.length; i++)
            _StepEditor(
              index: i + 1,
              row: _rows[i],
              onRemove: () => setState(() {
                _rows.removeAt(i).dispose();
              }),
            ),
          SerialDialogError(message: _error),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SerialButton(label: t.common.save, primary: true, onPressed: _save),
      ],
    );
  }
}

class _Pair {
  _Pair(String delay, String data)
    : delay = TextEditingController(text: delay),
      data = TextEditingController(text: data);

  final TextEditingController delay;
  final TextEditingController data;

  void dispose() {
    delay.dispose();
    data.dispose();
  }
}

class _StepRow {
  _StepRow(String delay, String data, String note)
    : delay = TextEditingController(text: delay),
      data = TextEditingController(text: data),
      note = TextEditingController(text: note);

  final TextEditingController delay;
  final TextEditingController data;
  final TextEditingController note;

  void dispose() {
    delay.dispose();
    data.dispose();
    note.dispose();
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
            width: 84,
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

class _LineEditor extends StatelessWidget {
  const _LineEditor({
    required this.index,
    required this.delay,
    required this.data,
    required this.onRemove,
  });

  final int index;
  final TextEditingController delay;
  final TextEditingController data;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$index',
              textAlign: TextAlign.right,
              style: AppTextStyles.mono(
                Theme.of(context).colorScheme,
                fontSize: 12,
                color: SerialPalette.of(context).muted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          SizedBox(
            width: 92,
            child: SerialField(
              controller: delay,
              mono: true,
              hint: t.serial.reply.delayHint,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: SerialField(
              controller: data,
              mono: true,
              hint: t.serial.reply.dataHint,
            ),
          ),
          SerialLinkButton(
            label: t.serial.dialog.remove,
            danger: true,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _StepEditor extends StatelessWidget {
  const _StepEditor({
    required this.index,
    required this.row,
    required this.onRemove,
  });

  final int index;
  final _StepRow row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$index',
              textAlign: TextAlign.right,
              style: AppTextStyles.mono(
                Theme.of(context).colorScheme,
                fontSize: 12,
                color: SerialPalette.of(context).muted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          SizedBox(
            width: 72,
            child: SerialField(controller: row.delay, mono: true),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: SerialField(
              controller: row.data,
              mono: true,
              hint: t.serial.batch.dataHint,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          SizedBox(
            width: 120,
            child: SerialField(
              controller: row.note,
              hint: t.serial.batch.noteHint,
            ),
          ),
          SerialLinkButton(
            label: t.serial.dialog.remove,
            danger: true,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
