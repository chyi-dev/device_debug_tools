import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 自绘窗口按钮：最小化、最大化/还原、关闭。系统标题栏已在 bootstrap 中隐藏。
class AppWindowButtons extends StatefulWidget {
  const AppWindowButtons({
    super.key,
    required this.height,
    required this.foreground,
    required this.hover,
  });

  final double height;
  final Color foreground;
  final Color hover;

  @override
  State<AppWindowButtons> createState() => _AppWindowButtonsState();
}

class _AppWindowButtonsState extends State<AppWindowButtons>
    with WindowListener {
  static const _closeHover = Color(0xffe81123);

  var _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _syncMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) setState(() => _maximized = maximized);
    } catch (_) {
      // 测试环境无原生插件，保持默认状态。
    }
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CaptionButton(
          icon: Icons.remove,
          height: widget.height,
          foreground: widget.foreground,
          hover: widget.hover,
          onPressed: windowManager.minimize,
        ),
        _CaptionButton(
          icon: _maximized ? Icons.filter_none : Icons.crop_square,
          iconSize: _maximized ? 13 : 16,
          height: widget.height,
          foreground: widget.foreground,
          hover: widget.hover,
          onPressed: () =>
              _maximized ? windowManager.unmaximize() : windowManager.maximize(),
        ),
        _CaptionButton(
          icon: Icons.close,
          height: widget.height,
          foreground: widget.foreground,
          hover: _closeHover,
          hoverForeground: Colors.white,
          onPressed: windowManager.close,
        ),
      ],
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.icon,
    required this.height,
    required this.foreground,
    required this.hover,
    required this.onPressed,
    this.iconSize = 16,
    this.hoverForeground,
  });

  static const double width = 46;

  final IconData icon;
  final double iconSize;
  final double height;
  final Color foreground;
  final Color hover;
  final Color? hoverForeground;
  final VoidCallback onPressed;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: _CaptionButton.width,
          height: widget.height,
          color: _hovered ? widget.hover : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _hovered
                ? (widget.hoverForeground ?? widget.foreground)
                : widget.foreground,
          ),
        ),
      ),
    );
  }
}

/// 应用图标，与 `doc/design/icon/app_icon_small.svg` 一致（48 坐标系等比缩放）。
class AppWindowIcon extends StatelessWidget {
  const AppWindowIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _AppIconPainter()),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  const _AppIconPainter();

  static const _body = Color(0xff1f2329);
  static const _bar = Color(0xff1769c2);
  static const _wave = Color(0xfff7f8fa);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48);
    canvas.drawRRect(
      RRect.fromLTRBR(0, 6, 48, 42, const Radius.circular(1.5)),
      Paint()..color = _body,
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        0,
        6,
        48,
        12,
        topLeft: const Radius.circular(1.5),
        topRight: const Radius.circular(1.5),
      ),
      Paint()..color = _bar,
    );
    final wave = Path()
      ..moveTo(6, 21)
      ..lineTo(15, 21)
      ..lineTo(15, 33)
      ..lineTo(33, 33)
      ..lineTo(33, 21)
      ..lineTo(42, 21);
    canvas.drawPath(
      wave,
      Paint()
        ..color = _wave
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
