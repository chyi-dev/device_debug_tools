/// 间距基准（桌面端逻辑 px，直接使用，如 `EdgeInsets.all(AppSpacing.lg)`）。
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// 面板 / 分组框圆角（Rams 表面 C）
  static const double radiusSm = 3;

  /// 对话框等略大于面板
  static const double radiusMd = 4;

  /// 少用；与半径体系对齐，避免再出现 12 的大圆角
  static const double radiusLg = 6;

  /// 按钮 / 输入 / 下拉圆角
  static const double radiusCtrl = 2;
}
