import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/data/serial_bytes.dart';
import '../../serial/data/serial_stamp.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../cubit/ble_console_state.dart';
import '../model/ble_models.dart';

class BleLogView extends StatefulWidget {
  const BleLogView({
    super.key,
    required this.state,
    required this.search,
    required this.onSearch,
    required this.searchFocus,
  });

  final BleConsoleState state;
  final String search;
  final ValueChanged<String> onSearch;
  final FocusNode searchFocus;

  @override
  State<BleLogView> createState() => _BleLogViewState();
}

class _BleLogViewState extends State<BleLogView> {
  final ScrollController _scroll = ScrollController();
  int _count = 0;

  @override
  void didUpdateWidget(covariant BleLogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.autoScroll && widget.state.lines.length != _count) {
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
                  t.ble.log.title,
                  style: AppTextStyles.body(
                    cs,
                  ).copyWith(color: palette.text, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  t.ble.log.records(count: widget.state.lines.length),
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
                      hintText: t.ble.log.search,
                      hintStyle: AppTextStyles.caption(
                        cs,
                      ).copyWith(color: palette.muted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          SerialMetrics.controlRadius,
                        ),
                        borderSide: BorderSide(color: palette.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          SerialMetrics.controlRadius,
                        ),
                        borderSide: BorderSide(color: palette.line),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      t.ble.log.empty,
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
                    itemBuilder: (context, index) {
                      return _entry(visible[index], t, palette, cs);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _entry(
    BleLogLine line,
    Translations t,
    SerialPalette palette,
    ColorScheme cs,
  ) {
    final headStyle = AppTextStyles.mono(
      cs,
      fontSize: 14,
      height: 1.6,
      color: palette.logPrompt,
    );
    final head = '[${fullStamp(line.time)}]# ';
    if (line.dir == LogDir.sys) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: head, style: headStyle),
            TextSpan(
              text: line.text,
              style: headStyle.copyWith(color: palette.logSys),
            ),
          ],
        ),
        softWrap: widget.state.wrap,
      );
    }
    final tag = line.dir == LogDir.rx ? t.serial.mark.recv : t.serial.mark.send;
    final color = line.dir == LogDir.rx ? palette.logRx : palette.logTx;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$head$tag ${t.serial.mark.hex}>\n', style: headStyle),
          TextSpan(
            text: SerialBytes.toHex(line.bytes ?? const []),
            style: AppTextStyles.mono(cs, fontSize: 14, height: 1.6, color: color),
          ),
          const TextSpan(text: '\n'),
        ],
      ),
      softWrap: widget.state.wrap,
    );
  }
}

List<BleLogLine> _visible(BleConsoleState state, String search) {
  if (search.isEmpty) return state.lines;
  final q = search.toLowerCase();
  return [
    for (final line in state.lines)
      if (line.text.toLowerCase().contains(q) ||
          SerialBytes.toHex(line.bytes ?? const []).toLowerCase().contains(q))
        line,
  ];
}
