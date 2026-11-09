import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/serial_palette.dart';
import '../../features/serial/serial_metrics.dart';
import '../storage/user_prefs_storage.dart';
import 'console_layout.dart';

enum AppSplitAxis { horizontal, vertical }

/// F 稿分割条：8px 热区，常态 1px 线，悬停/拖动加粗为 accent。
class AppSplitHandle extends StatefulWidget {
  const AppSplitHandle({
    super.key,
    required this.axis,
    required this.onDrag,
    this.onDoubleTap,
  });

  final AppSplitAxis axis;
  final ValueChanged<double> onDrag;
  final VoidCallback? onDoubleTap;

  @override
  State<AppSplitHandle> createState() => _AppSplitHandleState();
}

class _AppSplitHandleState extends State<AppSplitHandle> {
  var _hover = false;
  var _dragging = false;

  bool get _active => _hover || _dragging;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final horizontal = widget.axis == AppSplitAxis.horizontal;
    final thickness = _active ? 2.0 : SerialMetrics.splitLine;
    final color = _active ? palette.accent : palette.line;

    return MouseRegion(
      cursor: horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onDoubleTap,
        onHorizontalDragStart: horizontal
            ? (_) => setState(() => _dragging = true)
            : null,
        onHorizontalDragUpdate: horizontal
            ? (details) => widget.onDrag(details.delta.dx)
            : null,
        onHorizontalDragEnd: horizontal
            ? (_) => setState(() => _dragging = false)
            : null,
        onHorizontalDragCancel: horizontal
            ? () => setState(() => _dragging = false)
            : null,
        onVerticalDragStart: horizontal
            ? null
            : (_) => setState(() => _dragging = true),
        onVerticalDragUpdate: horizontal
            ? null
            : (details) => widget.onDrag(details.delta.dy),
        onVerticalDragEnd: horizontal
            ? null
            : (_) => setState(() => _dragging = false),
        onVerticalDragCancel: horizontal
            ? null
            : () => setState(() => _dragging = false),
        child: SizedBox(
          width: horizontal ? SerialMetrics.splitHit : null,
          height: horizontal ? null : SerialMetrics.splitHit,
          child: Center(
            child: Container(
              width: horizontal ? thickness : 48,
              height: horizontal ? 48 : thickness,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 调试台主体：左 | 中（日志/脚本/发送）| 右，分区可拖并持久化。
class AppConsoleShell extends StatefulWidget {
  const AppConsoleShell({
    super.key,
    required this.left,
    required this.centerTop,
    required this.send,
    required this.right,
    required this.compact,
    required this.toolsVisible,
    required this.scriptVisible,
    this.scriptDock,
    this.onCollapseLeft,
    this.onCollapseRight,
  });

  final Widget left;
  final Widget centerTop;
  final Widget? scriptDock;
  final Widget send;
  final Widget right;
  final bool compact;
  final bool toolsVisible;
  final bool scriptVisible;
  final VoidCallback? onCollapseLeft;
  final VoidCallback? onCollapseRight;

  @override
  State<AppConsoleShell> createState() => _AppConsoleShellState();
}

class _AppConsoleShellState extends State<AppConsoleShell> {
  late ConsoleLayout _layout;
  Timer? _saveTimer;
  var _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final prefs = context.read<UserPrefsStorage>();
    _layout = ConsoleLayout.fromPrefs(prefs);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  void _persist() {
    _saveTimer?.cancel();
    _saveTimer = Timer(SerialMetrics.layoutSaveDebounce, () {
      if (!mounted) return;
      final prefs = context.read<UserPrefsStorage>();
      // 保留脚本坞横拖写入的 scriptLogWidth，避免外壳覆写。
      final merged = _layout.copyWith(
        scriptLogWidth: ConsoleLayout.fromPrefs(prefs).scriptLogWidth,
      );
      prefs.saveConsoleLayout(merged.toMap());
    });
  }

  void _update(ConsoleLayout next, {bool collapseCheck = false}) {
    final clamped = next.clamped();
    setState(() => _layout = clamped);
    _persist();
    if (!collapseCheck) return;
    if (!widget.compact &&
        next.leftWidth < SerialMetrics.sidebarMin &&
        widget.onCollapseLeft != null) {
      widget.onCollapseLeft!();
    }
    if (widget.toolsVisible &&
        next.rightWidth < SerialMetrics.toolsMin &&
        widget.onCollapseRight != null) {
      widget.onCollapseRight!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLeft = !widget.compact;
    final showRight = widget.toolsVisible;
    final showScript = widget.scriptVisible && widget.scriptDock != null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLeft) ...[
            SizedBox(width: _layout.leftWidth, child: widget.left),
            AppSplitHandle(
              axis: AppSplitAxis.horizontal,
              onDrag: (dx) => _update(
                _layout.copyWith(leftWidth: _layout.leftWidth + dx),
                collapseCheck: true,
              ),
              onDoubleTap: () => _update(
                _layout.copyWith(leftWidth: ConsoleLayout.defaults.leftWidth),
              ),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: widget.centerTop),
                if (showScript) ...[
                  AppSplitHandle(
                    axis: AppSplitAxis.vertical,
                    onDrag: (dy) => _update(
                      _layout.copyWith(
                        scriptHeight: _layout.scriptHeight + dy,
                      ),
                    ),
                    onDoubleTap: () => _update(
                      _layout.copyWith(
                        scriptHeight: ConsoleLayout.defaults.scriptHeight,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: _layout.scriptHeight,
                    child: widget.scriptDock,
                  ),
                ],
                AppSplitHandle(
                  axis: AppSplitAxis.vertical,
                  onDrag: (dy) => _update(
                    _layout.copyWith(sendHeight: _layout.sendHeight - dy),
                  ),
                  onDoubleTap: () => _update(
                    _layout.copyWith(
                      sendHeight: ConsoleLayout.defaults.sendHeight,
                    ),
                  ),
                ),
                SizedBox(height: _layout.sendHeight, child: widget.send),
              ],
            ),
          ),
          if (showRight) ...[
            AppSplitHandle(
              axis: AppSplitAxis.horizontal,
              onDrag: (dx) => _update(
                _layout.copyWith(rightWidth: _layout.rightWidth - dx),
                collapseCheck: true,
              ),
              onDoubleTap: () => _update(
                _layout.copyWith(rightWidth: ConsoleLayout.defaults.rightWidth),
              ),
            ),
            SizedBox(width: _layout.rightWidth, child: widget.right),
          ],
        ],
      ),
    );
  }
}

/// 脚本坞内：编辑器 | 运行日志。
class AppScriptDockSplit extends StatefulWidget {
  const AppScriptDockSplit({
    super.key,
    required this.editor,
    required this.runLog,
  });

  final Widget editor;
  final Widget runLog;

  @override
  State<AppScriptDockSplit> createState() => _AppScriptDockSplitState();
}

class _AppScriptDockSplitState extends State<AppScriptDockSplit> {
  late double _logWidth;
  Timer? _saveTimer;
  var _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _logWidth = ConsoleLayout.fromPrefs(
      context.read<UserPrefsStorage>(),
    ).scriptLogWidth;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  void _persist(double width) {
    _saveTimer?.cancel();
    _saveTimer = Timer(SerialMetrics.layoutSaveDebounce, () {
      if (!mounted) return;
      final prefs = context.read<UserPrefsStorage>();
      final layout = ConsoleLayout.fromPrefs(
        prefs,
      ).copyWith(scriptLogWidth: width).clamped();
      prefs.saveConsoleLayout(layout.toMap());
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final maxLog = (box.maxWidth * 0.55).clamp(
          SerialMetrics.scriptLogMin,
          SerialMetrics.scriptLogMax,
        );
        final logWidth = _logWidth.clamp(
          SerialMetrics.scriptLogMin,
          maxLog.toDouble(),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.editor),
            AppSplitHandle(
              axis: AppSplitAxis.horizontal,
              onDrag: (dx) {
                final next = (logWidth - dx).clamp(
                  SerialMetrics.scriptLogMin,
                  maxLog.toDouble(),
                );
                setState(() => _logWidth = next);
                _persist(next);
              },
              onDoubleTap: () {
                setState(() => _logWidth = SerialMetrics.scriptLog);
                _persist(SerialMetrics.scriptLog);
              },
            ),
            SizedBox(width: logWidth, child: widget.runLog),
          ],
        );
      },
    );
  }
}
