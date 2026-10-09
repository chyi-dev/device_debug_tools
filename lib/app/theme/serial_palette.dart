import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 串口调试台颜色 token，白底经典 / 黑底经典各一套。
class SerialPalette extends ThemeExtension<SerialPalette> {
  const SerialPalette({
    required this.win,
    required this.panel,
    required this.field,
    required this.line,
    required this.line2,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentInk,
    required this.hover,
    required this.logBg,
    required this.logPrompt,
    required this.logRx,
    required this.logTx,
    required this.logSys,
    required this.mark,
    required this.on,
    required this.off,
    required this.lampIdle,
  });

  final Color win;
  final Color panel;
  final Color field;
  final Color line;
  final Color line2;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentInk;
  final Color hover;
  final Color logBg;
  final Color logPrompt;
  final Color logRx;
  final Color logTx;
  final Color logSys;
  final Color mark;
  final Color on;
  final Color off;
  final Color lampIdle;

  static const light = SerialPalette(
    win: AppColors.serialWin,
    panel: AppColors.serialPanel,
    field: AppColors.serialField,
    line: AppColors.serialLine,
    line2: AppColors.serialLine2,
    text: AppColors.serialText,
    muted: AppColors.serialMuted,
    accent: AppColors.serialAccent,
    accentInk: AppColors.serialAccentInk,
    hover: AppColors.serialHover,
    logBg: AppColors.serialLogBg,
    logPrompt: AppColors.serialLogPrompt,
    logRx: AppColors.serialLogRx,
    logTx: AppColors.serialLogTx,
    logSys: AppColors.serialLogSys,
    mark: AppColors.serialMark,
    on: AppColors.serialOn,
    off: AppColors.serialOff,
    lampIdle: AppColors.serialLampIdle,
  );

  static const dark = SerialPalette(
    win: AppColors.serialWinDark,
    panel: AppColors.serialPanelDark,
    field: AppColors.serialFieldDark,
    line: AppColors.serialLineDark,
    line2: AppColors.serialLine2Dark,
    text: AppColors.serialTextDark,
    muted: AppColors.serialMutedDark,
    accent: AppColors.serialAccentDark,
    accentInk: AppColors.serialAccentInkDark,
    hover: AppColors.serialHoverDark,
    logBg: AppColors.serialLogBgDark,
    logPrompt: AppColors.serialLogPromptDark,
    logRx: AppColors.serialLogRxDark,
    logTx: AppColors.serialLogTxDark,
    logSys: AppColors.serialLogSysDark,
    mark: AppColors.serialMarkDark,
    on: AppColors.serialOnDark,
    off: AppColors.serialOffDark,
    lampIdle: AppColors.serialLampIdleDark,
  );

  static SerialPalette of(BuildContext context) {
    final palette = Theme.of(context).extension<SerialPalette>();
    assert(palette != null, 'SerialPalette 未注册到 ThemeData');
    return palette!;
  }

  @override
  SerialPalette copyWith({
    Color? win,
    Color? panel,
    Color? field,
    Color? line,
    Color? line2,
    Color? text,
    Color? muted,
    Color? accent,
    Color? accentInk,
    Color? hover,
    Color? logBg,
    Color? logPrompt,
    Color? logRx,
    Color? logTx,
    Color? logSys,
    Color? mark,
    Color? on,
    Color? off,
    Color? lampIdle,
  }) {
    return SerialPalette(
      win: win ?? this.win,
      panel: panel ?? this.panel,
      field: field ?? this.field,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      hover: hover ?? this.hover,
      logBg: logBg ?? this.logBg,
      logPrompt: logPrompt ?? this.logPrompt,
      logRx: logRx ?? this.logRx,
      logTx: logTx ?? this.logTx,
      logSys: logSys ?? this.logSys,
      mark: mark ?? this.mark,
      on: on ?? this.on,
      off: off ?? this.off,
      lampIdle: lampIdle ?? this.lampIdle,
    );
  }

  @override
  SerialPalette lerp(ThemeExtension<SerialPalette>? other, double t) {
    if (other is! SerialPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SerialPalette(
      win: mix(win, other.win),
      panel: mix(panel, other.panel),
      field: mix(field, other.field),
      line: mix(line, other.line),
      line2: mix(line2, other.line2),
      text: mix(text, other.text),
      muted: mix(muted, other.muted),
      accent: mix(accent, other.accent),
      accentInk: mix(accentInk, other.accentInk),
      hover: mix(hover, other.hover),
      logBg: mix(logBg, other.logBg),
      logPrompt: mix(logPrompt, other.logPrompt),
      logRx: mix(logRx, other.logRx),
      logTx: mix(logTx, other.logTx),
      logSys: mix(logSys, other.logSys),
      mark: mix(mark, other.mark),
      on: mix(on, other.on),
      off: mix(off, other.off),
      lampIdle: mix(lampIdle, other.lampIdle),
    );
  }
}
