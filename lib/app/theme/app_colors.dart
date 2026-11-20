import 'package:flutter/material.dart';

abstract final class AppColors {
  /// 与串口台 accent 对齐（Rams 表面 C）
  static const Color primary = Color(0xFF3D5A80);
  static const Color primaryDark = Color(0xFF2C425F);
  static const Color primaryLight = Color(0xFFE4E8E6);

  static const Color background = Color(0xFFEBECEB);
  static const Color warning = Color(0xFFE6A23C);
  static const Color error = Color(0xFFB33A32);

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

  // 串口调试台 · Rams 仪器台浅色（doc/shell-redesign/surface-direction-approved.md）
  static const Color serialWin = Color(0xFFEBECEB);
  static const Color serialPanel = Color(0xFFF5F5F4);
  static const Color serialField = Color(0xFFFFFFFF);
  static const Color serialLine = Color(0xFF9A9E9C);
  static const Color serialLine2 = Color(0xFFD4D6D4);
  static const Color serialText = Color(0xFF1A1C1B);
  static const Color serialMuted = Color(0xFF5C615E);
  static const Color serialAccent = Color(0xFF3D5A80);
  static const Color serialAccentBorder = Color(0xFF2C425F);
  static const Color serialAccentInk = Color(0xFFFFFFFF);
  static const Color serialHover = Color(0xFFE4E8E6);
  static const Color serialLogBg = Color(0xFFFFFFFF);
  static const Color serialLogPrompt = Color(0xFF6A706C);
  static const Color serialLogRx = Color(0xFF1A1C1B);
  static const Color serialLogTx = Color(0xFF2C425F);
  static const Color serialLogSys = Color(0xFF7A4E00);
  static const Color serialMark = Color(0xFFF0E2A8);
  static const Color serialOn = Color(0xFF1F7A45);
  static const Color serialOff = Color(0xFFB33A32);
  static const Color serialLampIdle = Color(0xFFB4B8B5);

  // 串口调试台 · Rams 仪器台深色
  static const Color serialWinDark = Color(0xFF141516);
  static const Color serialPanelDark = Color(0xFF1C1E1F);
  static const Color serialFieldDark = Color(0xFF262829);
  static const Color serialLineDark = Color(0xFF3A3E40);
  static const Color serialLine2Dark = Color(0xFF2A2E30);
  static const Color serialTextDark = Color(0xFFE6E8E7);
  static const Color serialMutedDark = Color(0xFFA3A8A5);
  static const Color serialAccentDark = Color(0xFF7A9CC6);
  static const Color serialAccentBorderDark = Color(0xFF9BB4D4);
  static const Color serialAccentInkDark = Color(0xFFFFFFFF);
  static const Color serialHoverDark = Color(0xFF2A2E30);
  static const Color serialLogBgDark = Color(0xFF0E1010);
  static const Color serialLogPromptDark = Color(0xFF8B9190);
  static const Color serialLogRxDark = Color(0xFF9FD6B4);
  static const Color serialLogTxDark = Color(0xFFA8C4E6);
  static const Color serialLogSysDark = Color(0xFFE0B85A);
  static const Color serialMarkDark = Color(0xFF5A4E18);
  static const Color serialOnDark = Color(0xFF3CCF7A);
  static const Color serialOffDark = Color(0xFFEF5B50);
  static const Color serialLampIdleDark = Color(0xFF4A4F4D);

  // 连接页签协议色（doc/design/option-a）
  static const Color protocolSerial = Color(0xFF1F9D55);
  static const Color protocolBle = Color(0xFF2F76D2);
  static const Color protocolMqtt = Color(0xFFB86B0A);
  static const Color protocolTcp = Color(0xFF0F766E);
  static const Color protocolUdp = Color(0xFF7C3AED);
  static const Color protocolSerialDark = Color(0xFF3CCF7A);
  static const Color protocolBleDark = Color(0xFF5B9FFF);
  static const Color protocolMqttDark = Color(0xFFF0A04B);
  static const Color protocolTcpDark = Color(0xFF2DD4BF);
  static const Color protocolUdpDark = Color(0xFFA78BFA);
}
