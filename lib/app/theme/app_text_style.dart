import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static TextStyle titleLarge(ColorScheme cs) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      );

  static TextStyle titleMedium(ColorScheme cs) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      );

  static TextStyle body(ColorScheme cs) => TextStyle(
        fontSize: 14,
        height: 1.4,
        color: cs.onSurface,
      );

  static TextStyle caption(ColorScheme cs) => TextStyle(
        fontSize: 12,
        color: cs.onSurfaceVariant,
      );

  static const monoFallback = [
    'Cascadia Mono',
    'Consolas',
    'SF Mono',
    'Menlo',
    'DejaVu Sans Mono',
  ];

  static TextStyle mono(
    ColorScheme cs, {
    double fontSize = 13,
    double height = 1.4,
    Color? color,
    FontWeight? fontWeight,
  }) =>
      TextStyle(
        fontSize: fontSize,
        height: height,
        fontFamily: 'monospace',
        fontFamilyFallback: monoFallback,
        color: color ?? cs.onSurface,
        fontWeight: fontWeight,
      );
}
