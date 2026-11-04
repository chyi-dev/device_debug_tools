import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/socket_console_state.dart';
import '../model/socket_models.dart';
import '../../serial/data/serial_bytes.dart';
import '../../serial/data/serial_stamp.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import 'socket_l10n.dart';

class SocketLogView extends StatefulWidget {
  const SocketLogView({
    super.key,
    required this.state,
    required this.search,
    required this.onSearch,
    required this.searchFocus,
  });

  final SocketConsoleState state;
  final String search;
  final ValueChanged<String> onSearch;
  final FocusNode searchFocus;

  @override
  State<SocketLogView> createState() => _SocketLogViewState();
}

class _SocketLogViewState extends State<SocketLogView> {
  final ScrollController _scroll = ScrollController();
  int _count = 0;

  @override
  void didUpdateWidget(covariant SocketLogView oldWidget) {
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
    final state = widget.state;
    final hits = _matchCount(state, widget.search, t);
    final meta = [
      if (widget.search.isNotEmpty) t.socket.log.matches(count: hits),
      t.socket.log.records(count: state.lines.length),
      if (state.hideRx) t.socket.log.rxHidden,
    ].join(' · ');
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
                  t.socket.log.title,
                  style: AppTextStyles.body(
                    cs,
                  ).copyWith(color: palette.text, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mono(
                      cs,
                      fontSize: 12,
                      color: palette.muted,
                    ),
                  ),
                ),
                SerialSearchField(
                  focusNode: widget.searchFocus,
                  hint: t.socket.log.search,
                  onChanged: widget.onSearch,
                ),
              ],
            ),
          ),
          Expanded(
            child: SelectionArea(
              child: Scrollbar(
                controller: _scroll,
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  children: [
                    if (_visible(state).isEmpty)
                      Text(
                        state.open ? t.socket.log.waiting : t.socket.log.closed,
                        style: AppTextStyles.body(
                          cs,
                        ).copyWith(color: palette.muted),
                      )
                    else if (!state.logMode)
                      _stream(state, palette, cs)
                    else
                      for (final line in _visible(state))
                        _entry(line, t, palette, cs),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<SocketLogLine> _visible(SocketConsoleState state) {
    if (!state.logMode) {
      return [
        for (final line in state.lines)
          if (line.dir == LogDir.rx) line,
      ];
    }
    return [
      for (final line in state.lines)
        if (!(state.hideRx && line.dir == LogDir.rx)) line,
    ];
  }

  Widget _stream(
    SocketConsoleState state,
    SerialPalette palette,
    ColorScheme cs,
  ) {
    final style = AppTextStyles.mono(
      cs,
      fontSize: 14,
      height: 1.6,
      color: palette.logRx,
    );
    final buffer = StringBuffer();
    for (final line in _visible(state)) {
      final bytes = line.bytes;
      if (bytes == null) continue;
      buffer.write(
        state.rxFormat == DataFormat.hex
            ? '${SerialBytes.toHex(bytes)} '
            : SerialBytes.toAscii(bytes),
      );
    }
    return Text.rich(
      TextSpan(
        children: _highlight(
          buffer.toString(),
          widget.search,
          style,
          palette.mark,
        ),
      ),
      softWrap: state.wrap,
    );
  }

  Widget _entry(
    SocketLogLine line,
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
            ..._highlight(
              socketSysText(t, line),
              widget.search,
              headStyle.copyWith(color: palette.logSys),
              palette.mark,
            ),
          ],
        ),
        softWrap: widget.state.wrap,
      );
    }
    final tag = line.dir == LogDir.rx ? t.serial.mark.recv : t.serial.mark.send;
    final fmt = widget.state.rxFormat == DataFormat.hex
        ? t.serial.mark.hex
        : t.serial.mark.ascii;
    final color = line.dir == LogDir.rx ? palette.logRx : palette.logTx;
    final bytes = line.bytes ?? const <int>[];
    final body = widget.state.rxFormat == DataFormat.hex
        ? SerialBytes.toHex(bytes)
        : SerialBytes.toAscii(bytes);
    final dataStyle = AppTextStyles.mono(
      cs,
      fontSize: 14,
      height: 1.6,
      color: color,
    );
    final peer = line.peer;
    final peerSuffix = peer == null || peer.isEmpty
        ? ''
        : ' · ${t.socket.log.peerLabel(peer: peer)}';
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$head$tag $fmt$peerSuffix>\n', style: headStyle),
          ..._highlight(body, widget.search, dataStyle, palette.mark),
          const TextSpan(text: '\n'),
        ],
      ),
      softWrap: widget.state.wrap,
    );
  }
}

int _matchCount(SocketConsoleState state, String query, Translations t) {
  if (query.isEmpty) return 0;
  var count = 0;
  final q = query.toLowerCase();
  for (final line in state.lines) {
    if (state.hideRx && line.dir == LogDir.rx) continue;
    if (!state.logMode && line.dir != LogDir.rx) continue;
    final text = line.dir == LogDir.sys
        ? socketSysText(t, line)
        : (state.rxFormat == DataFormat.hex
              ? SerialBytes.toHex(line.bytes ?? const [])
              : SerialBytes.toAscii(line.bytes ?? const []));
    var i = 0;
    final lower = text.toLowerCase();
    while (true) {
      final found = lower.indexOf(q, i);
      if (found < 0) break;
      count++;
      i = found + q.length;
    }
  }
  return count;
}

List<InlineSpan> _highlight(
  String text,
  String query,
  TextStyle style,
  Color mark,
) {
  if (query.isEmpty || text.isEmpty) {
    return [TextSpan(text: text, style: style)];
  }
  final lower = text.toLowerCase();
  final q = query.toLowerCase();
  final spans = <InlineSpan>[];
  var i = 0;
  while (i < text.length) {
    final found = lower.indexOf(q, i);
    if (found < 0) {
      spans.add(TextSpan(text: text.substring(i), style: style));
      break;
    }
    if (found > i) {
      spans.add(TextSpan(text: text.substring(i, found), style: style));
    }
    spans.add(
      TextSpan(
        text: text.substring(found, found + q.length),
        style: style.copyWith(backgroundColor: mark),
      ),
    );
    i = found + q.length;
  }
  return spans;
}
