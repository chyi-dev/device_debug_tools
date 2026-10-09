import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF409EFF);
  static const Color primaryDark = Color(0xFF0060A9);
  static const Color primaryLight = Color(0xFFECF5FF);

  static const Color background = Color(0xFFF5F7FA);
  static const Color warning = Color(0xFFE6A23C);
  static const Color error = Color(0xFFF56C6C);

  // SnackBar · success
  static const Color snackSuccessBg = Color(0xFFD1FAE5);
  static const Color snackSuccessFg = Color(0xFF047857);
  static const Color snackSuccessBgDark = Color(0xFF064E3B);
  static const Color snackSuccessFgDark = Color(0xFF6EE7B7);

  // SnackBar · error
  static const Color snackErrorBg = Color(0xFFFEE2E2);
  static const Color snackErrorFg = Color(0xFFB91C1C);
  static const Color snackErrorBgDark = Color(0xFF7F1D1D);
  static const Color snackErrorFgDark = Color(0xFFFCA5A5);

  // SnackBar · info
  static const Color snackInfoBg = Color(0xFFDBEAFE);
  static const Color snackInfoFg = Color(0xFF1D4ED8);
  static const Color snackInfoBgDark = Color(0xFF1E3A8A);
  static const Color snackInfoFgDark = Color(0xFF93C5FD);

  // 串口调试台 · 白底经典（doc/design/design.md §2）
  static const Color serialWin = Color(0xFFE9EDF1);
  static const Color serialPanel = Color(0xFFF7F8FA);
  static const Color serialField = Color(0xFFFFFFFF);
  static const Color serialLine = Color(0xFFC5CED7);
  static const Color serialLine2 = Color(0xFFDFE4E9);
  static const Color serialText = Color(0xFF1F2933);
  static const Color serialMuted = Color(0xFF56616E);
  static const Color serialAccent = Color(0xFF1769C2);
  static const Color serialAccentInk = Color(0xFFFFFFFF);
  static const Color serialHover = Color(0xFFE3EBF5);
  static const Color serialLogBg = Color(0xFFFFFFFF);
  static const Color serialLogPrompt = Color(0xFF6B7480);
  static const Color serialLogRx = Color(0xFF1B2630);
  static const Color serialLogTx = Color(0xFF1461B8);
  static const Color serialLogSys = Color(0xFF9A5A00);
  static const Color serialMark = Color(0xFFFFE28A);
  static const Color serialOn = Color(0xFF1F9D55);
  static const Color serialOff = Color(0xFFC8392F);
  static const Color serialLampIdle = Color(0xFFB9C1CA);

  // 串口调试台 · 黑底经典
  static const Color serialWinDark = Color(0xFF16191D);
  static const Color serialPanelDark = Color(0xFF1F2329);
  static const Color serialFieldDark = Color(0xFF272C33);
  static const Color serialLineDark = Color(0xFF3A414A);
  static const Color serialLine2Dark = Color(0xFF2E343C);
  static const Color serialTextDark = Color(0xFFE3E7EC);
  static const Color serialMutedDark = Color(0xFFA1AAB5);
  static const Color serialAccentDark = Color(0xFF4C9BF0);
  static const Color serialAccentInkDark = Color(0xFF0C1624);
  static const Color serialHoverDark = Color(0xFF2B323B);
  static const Color serialLogBgDark = Color(0xFF0D1013);
  static const Color serialLogPromptDark = Color(0xFF8B949E);
  static const Color serialLogRxDark = Color(0xFF7FE0A6);
  static const Color serialLogTxDark = Color(0xFF8CC2FF);
  static const Color serialLogSysDark = Color(0xFFE5B54A);
  static const Color serialMarkDark = Color(0xFF6B5A12);
  static const Color serialOnDark = Color(0xFF3CCF7A);
  static const Color serialOffDark = Color(0xFFEF5B50);
  static const Color serialLampIdleDark = Color(0xFF4A525C);
}
