import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/serial_console_cubit.dart';
import '../cubit/serial_console_state.dart';
import '../data/serial_stamp.dart';
import '../model/serial_models.dart';
import '../serial_metrics.dart';
import 'serial_chrome.dart';
import 'serial_editors.dart';
import 'serial_l10n.dart';

const double _codeSize = 13;
const double _codeHeight = 1.55;
const double _codePad = AppSpacing.sm;

/// 脚本页签下停靠在数据日志与发送框之间：左侧编辑器，右侧运行日志。
class SerialScriptDock extends StatelessWidget {
  const SerialScriptDock({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return BlocBuilder<SerialConsoleCubit, SerialConsoleState>(
      buildWhen: (previous, current) =>
          previous.scripts != current.scripts ||
          previous.scriptMeta != current.scriptMeta ||
          previous.scriptLog != current.scriptLog ||
          previous.selectedScriptId != current.selectedScriptId,
      builder: (context, state) {
        final script = state.selectedScript;
        if (script == null) return const SizedBox.shrink();
        final meta = state.scriptMeta[script.id] ?? const ScriptMeta();
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border.all(color: palette.line),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            children: [
              _DockHead(script: script, meta: meta),
              Divider(height: 1, color: palette.line),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final logWidth = math.min(
                      SerialMetrics.scriptLog,
                      box.maxWidth * 0.45,
                    );
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _CodeEditor(
                            key: ValueKey(script.id),
                            script: script,
                          ),
                        ),
                        VerticalDivider(width: 1, color: palette.line),
                        SizedBox(
                          width: logWidth,
                          child: _RunLog(entries: state.scriptLog),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 列表行与停靠区标题共用的钩子标记；编译失败时显示错误标记。
List<Widget> scriptHookChips(BuildContext context, ScriptMeta meta) {
  final s = Translations.of(context).serial.script;
  final palette = SerialPalette.of(context);
  final error = meta.error;
  if (error != null) {
    return [
      Tooltip(
        message: error,
        child: _Chip(s.broken, color: palette.off),
      ),
    ];
  }
  if (meta.hooks.isEmpty) return [_Chip(s.noHook)];
  return [for (final hook in meta.hooks) _Chip(scriptHookName(hook))];
}

/// 教程课表里标注这一课用哪个钩子。
Widget scriptHookChip(ScriptHook hook) => _Chip(scriptHookName(hook));

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final tone = color ?? palette.muted;
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs + 2),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color ?? palette.line),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: AppTextStyles.mono(
          Theme.of(context).colorScheme,
          fontSize: 12,
          color: tone,
        ),
      ),
    );
  }
}

class _DockHead extends StatelessWidget {
  const _DockHead({required this.script, required this.meta});

  final LuaScript script;
  final ScriptMeta meta;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final s = t.serial.script;
    final cubit = context.read<SerialConsoleCubit>();
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final muted = AppTextStyles.caption(cs).copyWith(color: palette.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              script.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(cs).copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...scriptHookChips(context, meta),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: s.editorHint,
              child: Text(
                '${script.enabled ? s.autoOn : s.autoOff} · ${s.editorHint}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SerialButton(
            label: s.run,
            small: true,
            primary: true,
            onPressed: () => cubit.runScript(script.id),
          ),
          const SizedBox(width: AppSpacing.xs),
          SerialLinkButton(
            label: s.rename,
            onPressed: () => showScriptRename(context, script),
          ),
          SerialLinkButton(
            label: t.common.delete,
            danger: true,
            onPressed: () => showSerialDelete(
              context,
              message: t.serial.dialog.deleteScript(name: script.name),
              onDelete: () => cubit.deleteScript(script.id),
            ),
          ),
          SerialLinkButton(
            label: s.fold,
            onPressed: () => cubit.setScriptDock(false),
          ),
        ],
      ),
    );
  }
}

class _CodeEditor extends StatefulWidget {
  const _CodeEditor({super.key, required this.script});

  final LuaScript script;

  @override
  State<_CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<_CodeEditor> {
  late final TextEditingController _code = TextEditingController(
    text: widget.script.code,
  );
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();
  final ScrollController _gutter = ScrollController();
  late final FocusNode _focus = FocusNode(onKeyEvent: _onKey);

  @override
  void initState() {
    super.initState();
    _vertical.addListener(_syncGutter);
  }

  @override
  void didUpdateWidget(covariant _CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.script.code != _code.text) _code.text = widget.script.code;
  }

  @override
  void dispose() {
    _vertical.removeListener(_syncGutter);
    _code.dispose();
    _vertical.dispose();
    _horizontal.dispose();
    _gutter.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _syncGutter() {
    if (!_gutter.hasClients) return;
    final max = _gutter.position.maxScrollExtent;
    _gutter.jumpTo(_vertical.offset.clamp(0, max));
  }

  /// Tab 插入两个空格，不移走焦点。
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.tab ||
        HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    if (event is KeyUpEvent) return KeyEventResult.handled;
    final value = _code.value;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : value.text.length;
    final end = sel.isValid ? sel.end : value.text.length;
    final text = value.text.replaceRange(start, end, '  ');
    _code.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + 2),
    );
    _changed(text);
    return KeyEventResult.handled;
  }

  void _changed(String text) {
    setState(() {});
    context.read<SerialConsoleCubit>().setScriptCode(widget.script.id, text);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final style = AppTextStyles.mono(
      cs,
      fontSize: _codeSize,
      height: _codeHeight,
      color: palette.logRx,
    );
    final strut = StrutStyle(
      fontFamily: style.fontFamily,
      fontFamilyFallback: style.fontFamilyFallback,
      fontSize: _codeSize,
      height: _codeHeight,
      forceStrutHeight: true,
    );
    final lines = _code.text.split('\n');
    final longest = lines.fold<int>(0, (n, line) => math.max(n, line.length));
    final charWidth =
        (TextPainter(
          text: TextSpan(text: '0' * 10, style: style),
          textDirection: TextDirection.ltr,
        )..layout()).width /
        10;
    return ColoredBox(
      color: palette.logBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            decoration: BoxDecoration(
              color: palette.panel,
              border: Border(right: BorderSide(color: palette.line2)),
            ),
            child: SingleChildScrollView(
              controller: _gutter,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm + 2,
                _codePad,
                AppSpacing.xs + 2,
                _codePad + 40,
              ),
              child: Text(
                [for (var i = 1; i <= lines.length; i++) '$i'].join('\n'),
                textAlign: TextAlign.right,
                strutStyle: strut,
                style: style.copyWith(color: palette.logPrompt),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final width = math.max(
                  box.maxWidth,
                  longest * charWidth + AppSpacing.lg * 2 + 24,
                );
                return Scrollbar(
                  controller: _horizontal,
                  child: SingleChildScrollView(
                    controller: _horizontal,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      height: box.maxHeight,
                      child: TextField(
                        controller: _code,
                        focusNode: _focus,
                        scrollController: _vertical,
                        expands: true,
                        maxLines: null,
                        style: style,
                        strutStyle: strut,
                        cursorColor: palette.text,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        autocorrect: false,
                        enableSuggestions: false,
                        smartDashesType: SmartDashesType.disabled,
                        smartQuotesType: SmartQuotesType.disabled,
                        onChanged: _changed,
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.fromLTRB(
                            AppSpacing.sm + 2,
                            _codePad,
                            AppSpacing.sm + 2,
                            _codePad,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RunLog extends StatefulWidget {
  const _RunLog({required this.entries});

  final List<ScriptLogEntry> entries;

  @override
  State<_RunLog> createState() => _RunLogState();
}

class _RunLogState extends State<_RunLog> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _toBottom();
  }

  @override
  void didUpdateWidget(covariant _RunLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries == widget.entries) return;
    final stick =
        !_scroll.hasClients ||
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 4;
    if (stick) _toBottom();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final s = t.serial.script;
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final entries = widget.entries;
    final mono = AppTextStyles.mono(cs, fontSize: 12, height: _codeHeight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm + 2,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.line2)),
          ),
          child: Row(
            children: [
              Text(
                s.logTitle,
                style: AppTextStyles.body(cs).copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  s.logCount(count: entries.length),
                  style: AppTextStyles.caption(
                    cs,
                  ).copyWith(color: palette.muted),
                ),
              ),
              SerialLinkButton(
                label: s.clear,
                onPressed: entries.isEmpty
                    ? null
                    : context.read<SerialConsoleCubit>().clearScriptLog,
              ),
            ],
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: palette.logBg,
            child: entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    child: Text(
                      s.logEmpty,
                      style: AppTextStyles.caption(
                        cs,
                      ).copyWith(color: palette.muted, height: 1.6),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: palette.line2),
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${clockStamp(entry.time)}  ',
                                style: mono.copyWith(color: palette.logPrompt),
                              ),
                              TextSpan(
                                text: '${entry.name}  ',
                                style: mono.copyWith(color: palette.logTx),
                              ),
                              TextSpan(
                                text: scriptLogText(t, entry),
                                style: mono.copyWith(
                                  color: entry.isError
                                      ? palette.off
                                      : palette.logRx,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
