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
    final panelRadius = BorderRadius.circular(AppSpacing.radiusSm);
    final controlRadius = BorderRadius.circular(AppSpacing.radiusCtrl);
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
        shape: RoundedRectangleBorder(
          borderRadius: panelRadius,
          side: BorderSide(color: palette.line),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      // 只设 border，不要写 enabled/focused：SerialField 等外层已画线且
      // decoration.border=none，主题若再带 enabled Outline 会叠成双框。
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(borderRadius: controlRadius),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.accentInk,
          disabledBackgroundColor: palette.accent.withValues(alpha: 0.6),
          disabledForegroundColor: palette.accentInk.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: controlRadius,
            side: BorderSide(color: palette.accentBorder),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          backgroundColor: palette.field,
          side: BorderSide(color: palette.line),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          visualDensity: VisualDensity.compact,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          visualDensity: VisualDensity.compact,
        ),
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
