/// 桌面端布局基准（逻辑 px，不随窗口缩放）。
abstract final class AppDesign {
  /// 表单/设置等内容区最大宽度。
  static const double contentMaxWidth = 720;

  /// 窗口宽度断点（用于 LayoutBuilder）。
  static const double breakpointMedium = 840;
  static const double breakpointExpanded = 1200;

  static WindowSizeClass sizeClassOf(double width) {
    if (width >= breakpointExpanded) return WindowSizeClass.expanded;
    if (width >= breakpointMedium) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }
}

enum WindowSizeClass { compact, medium, expanded }
