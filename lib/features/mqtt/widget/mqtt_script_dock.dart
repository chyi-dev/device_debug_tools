import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/data/serial_stamp.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_editors.dart';
import '../cubit/mqtt_console_cubit.dart';
import '../cubit/mqtt_console_state.dart';
import '../model/mqtt_models.dart';
import 'mqtt_l10n.dart';
import 'mqtt_script_panel.dart';

const double _codeSize = 13;
const double _codeHeight = 1.55;
const double _codePad = AppSpacing.sm;

/// 脚本页签下停靠在报文日志与发布框之间。
class MqttScriptDock extends StatelessWidget {
  const MqttScriptDock({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      buildWhen: (a, b) =>
          a.scripts != b.scripts ||
          a.scriptMeta != b.scriptMeta ||
          a.scriptLog != b.scriptLog ||
          a.selectedScriptId != b.selectedScriptId,
      builder: (context, state) {
        final script = state.selectedScript;
        if (script == null) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.panel,
              border: Border.all(color: palette.line),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: _RunLog(entries: state.scriptLog),
          );
        }
        final meta = state.scriptMeta[script.id] ?? const MqttScriptMeta();
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border.all(color: palette.line),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            children: [
              _Head(script: script, meta: meta),
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

class _Head extends StatelessWidget {
  const _Head({required this.script, required this.meta});

  final LuaScript script;
  final MqttScriptMeta meta;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final s = t.mqtt.script;
    final cubit = context.read<MqttConsoleCubit>();
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return SerialContextMenu(
      menu: [
        SerialMenuAction(
          label: s.rename,
          onTap: () => showMqttScriptRename(context, script),
        ),
        SerialMenuAction(
          label: t.common.duplicate,
          onTap: () => cubit.duplicateScript(script.id),
        ),
        SerialMenuAction(
          label: t.common.delete,
          danger: true,
          onTap: () => showSerialDelete(
            context,
            message: s.delete(name: script.name),
            onDelete: () => cubit.deleteScript(script.id),
          ),
        ),
      ],
      child: Padding(
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
            ...mqttHookChips(context, meta),
            Expanded(
              child: Text(
                '${script.enabled ? s.autoOn : s.autoOff} · ${s.editorHint}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
              ),
            ),
            SerialButton(
              label: s.run,
              small: true,
              primary: true,
              onPressed: () => cubit.runScript(script.id),
            ),
            const SizedBox(width: AppSpacing.xs),
            SerialLinkButton(
              label: s.fold,
              onPressed: () => cubit.setScriptDock(false),
            ),
          ],
        ),
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
    _gutter.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _syncGutter() {
    if (!_gutter.hasClients) return;
    final max = _gutter.position.maxScrollExtent;
    _gutter.jumpTo(_vertical.offset.clamp(0, max));
  }

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
    context.read<MqttConsoleCubit>().setScriptCode(widget.script.id, text);
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
    final lines = _code.text.isEmpty
        ? 1
        : '\n'.allMatches(_code.text).length + 1;
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
                AppSpacing.sm,
                _codePad,
                AppSpacing.xs,
                _codePad,
              ),
              child: Text(
                [for (var i = 1; i <= lines; i++) '$i'].join('\n'),
                textAlign: TextAlign.right,
                strutStyle: strut,
                style: style.copyWith(color: palette.logPrompt),
              ),
            ),
          ),
          Expanded(
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
              onChanged: _changed,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  _codePad,
                  AppSpacing.sm,
                  _codePad,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunLog extends StatelessWidget {
  const _RunLog({required this.entries});

  final List<MqttScriptLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final s = t.mqtt.script;
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.logTitle,
                  style: AppTextStyles.caption(
                    cs,
                  ).copyWith(color: palette.text),
                ),
              ),
              SerialLinkButton(
                label: s.clear,
                onPressed: context.read<MqttConsoleCubit>().clearScriptLog,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: palette.line),
        Expanded(
          child: entries.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    s.logEmpty,
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  children: [
                    for (final entry in entries)
                      Text(
                        '${clockStamp(entry.time)} ${entry.name} ${mqttScriptLogText(t, entry)}',
                        style: AppTextStyles.mono(
                          cs,
                          fontSize: 12,
                          height: _codeHeight,
                          color: entry.isError ? palette.off : palette.text,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
