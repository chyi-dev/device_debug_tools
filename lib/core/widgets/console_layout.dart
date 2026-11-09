import '../../features/serial/serial_metrics.dart';
import '../storage/user_prefs_storage.dart';

/// 调试台可拖分区尺寸；四协议全局共用一份。
class ConsoleLayout {
  const ConsoleLayout({
    required this.leftWidth,
    required this.rightWidth,
    required this.scriptHeight,
    required this.sendHeight,
    required this.scriptLogWidth,
  });

  final double leftWidth;
  final double rightWidth;
  final double scriptHeight;
  final double sendHeight;
  final double scriptLogWidth;

  static const defaults = ConsoleLayout(
    leftWidth: SerialMetrics.sidebar,
    rightWidth: SerialMetrics.tools,
    scriptHeight: SerialMetrics.scriptDock,
    sendHeight: SerialMetrics.sendHeight,
    scriptLogWidth: SerialMetrics.scriptLog,
  );

  factory ConsoleLayout.fromPrefs(UserPrefsStorage prefs) {
    final raw = prefs.readConsoleLayout();
    return defaults.copyWith(
      leftWidth: raw['leftWidth'],
      rightWidth: raw['rightWidth'],
      scriptHeight: raw['scriptHeight'],
      sendHeight: raw['sendHeight'],
      scriptLogWidth: raw['scriptLogWidth'],
    ).clamped();
  }

  ConsoleLayout copyWith({
    double? leftWidth,
    double? rightWidth,
    double? scriptHeight,
    double? sendHeight,
    double? scriptLogWidth,
  }) {
    return ConsoleLayout(
      leftWidth: leftWidth ?? this.leftWidth,
      rightWidth: rightWidth ?? this.rightWidth,
      scriptHeight: scriptHeight ?? this.scriptHeight,
      sendHeight: sendHeight ?? this.sendHeight,
      scriptLogWidth: scriptLogWidth ?? this.scriptLogWidth,
    );
  }

  ConsoleLayout clamped() {
    return ConsoleLayout(
      leftWidth: leftWidth.clamp(SerialMetrics.sidebarMin, 560),
      rightWidth: rightWidth.clamp(SerialMetrics.toolsMin, 560),
      scriptHeight: scriptHeight.clamp(
        SerialMetrics.scriptDockMin,
        SerialMetrics.scriptDockMax,
      ),
      sendHeight: sendHeight.clamp(
        SerialMetrics.sendMin,
        SerialMetrics.sendMax,
      ),
      scriptLogWidth: scriptLogWidth.clamp(
        SerialMetrics.scriptLogMin,
        SerialMetrics.scriptLogMax,
      ),
    );
  }

  Map<String, double> toMap() => {
    'leftWidth': leftWidth,
    'rightWidth': rightWidth,
    'scriptHeight': scriptHeight,
    'sendHeight': sendHeight,
    'scriptLogWidth': scriptLogWidth,
  };
}
