import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'serial_palette.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static const _fontFallback = [
    'Microsoft YaHei UI',
    'PingFang SC',
    'Noto Sans SC',
    'sans-serif',
  ];

  static ThemeData _build(Brightness brightness) {
    final palette =
        brightness == Brightness.light ? SerialPalette.light : SerialPalette.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      primary: palette.accent,
      brightness: brightness,
    );
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [palette],
      visualDensity: VisualDensity.compact,
      scaffoldBackgroundColor: palette.win,
      fontFamily: 'Segoe UI',
      fontFamilyFallback: _fontFallback,
      splashFactory: NoSplash.splashFactory,
      highlightColor: palette.hover,
      hoverColor: palette.hover,
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.panel,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        isDense: true,
      ),
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: palette.line),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.accent;
          return palette.field;
        }),
      ),
      radioTheme: RadioThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.accent;
          return palette.muted;
        }),
      ),
    );
  }
}
