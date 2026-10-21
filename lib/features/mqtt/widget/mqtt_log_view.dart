import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/data/serial_stamp.dart';
import '../../serial/serial_metrics.dart';
import '../cubit/mqtt_console_state.dart';
import '../model/mqtt_models.dart';

class MqttLogView extends StatefulWidget {
  const MqttLogView({
    super.key,
    required this.state,
    required this.search,
    required this.onSearch,
    required this.searchFocus,
    required this.onClear,
  });

  final MqttConsoleState state;
  final String search;
  final ValueChanged<String> onSearch;
  final FocusNode searchFocus;
  final VoidCallback onClear;

  @override
  State<MqttLogView> createState() => _MqttLogViewState();
}

class _MqttLogViewState extends State<MqttLogView> {
  final ScrollController _scroll = ScrollController();
  int _count = 0;

  @override
  void didUpdateWidget(covariant MqttLogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.lines.length != _count) {
      _count = widget.state.lines.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final visible = _visible(widget.state, widget.search);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.logBg,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        children: [
          Container(
            height: SerialMetrics.logHead,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: palette.panel,
              border: Border(bottom: BorderSide(color: palette.line)),
            ),
            child: Row(
              children: [
                Text(
                  t.mqtt.log.title,
                  style: AppTextStyles.body(
                    cs,
                  ).copyWith(color: palette.text, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  t.mqtt.log.records(count: widget.state.lines.length),
                  style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
                ),
                const Spacer(),
                SizedBox(
                  width: SerialMetrics.searchWidth,
                  child: TextField(
                    focusNode: widget.searchFocus,
                    onChanged: widget.onSearch,
                    style: AppTextStyles.caption(cs).copyWith(color: palette.text),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: t.mqtt.log.search,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          SerialMetrics.controlRadius,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: widget.onClear,
                  child: Text(t.common.delete),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      t.mqtt.log.empty,
                      style: AppTextStyles.mono(
                        cs,
                        fontSize: 14,
                        color: palette.logPrompt,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: visible.length,
                    itemBuilder: (context, index) =>
                        _entry(visible[index], palette, cs),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _entry(MqttLogLine line, SerialPalette palette, ColorScheme cs) {
    final headStyle = AppTextStyles.mono(
      cs,
      fontSize: 14,
      height: 1.6,
      color: palette.logPrompt,
    );
    final head = '[${fullStamp(line.time)}]# ';
    if (line.dir == MqttDir.sys) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: head, style: headStyle),
            TextSpan(
              text: line.payload,
              style: headStyle.copyWith(color: palette.logSys),
            ),
          ],
        ),
      );
    }
    final tag = line.dir == MqttDir.rx ? 'RECV' : 'PUB';
    final flags = 'QoS${line.qos}${line.retain ? ' RETAIN' : ''}';
    final color = line.dir == MqttDir.rx ? palette.logRx : palette.logTx;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$head$tag [${line.topic}] $flags>\n',
              style: headStyle,
            ),
            TextSpan(
              text: line.payload,
              style: AppTextStyles.mono(
                cs,
                fontSize: 14,
                height: 1.6,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<MqttLogLine> _visible(MqttConsoleState state, String search) {
  if (search.isEmpty) return state.lines;
  final q = search.toLowerCase();
  return [
    for (final line in state.lines)
      if (line.topic.toLowerCase().contains(q) ||
          line.payload.toLowerCase().contains(q))
        line,
  ];
}
