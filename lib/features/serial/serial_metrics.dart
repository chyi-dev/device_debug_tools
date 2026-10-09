import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// 设计稿固定尺寸。间距优先用 [AppSpacing]，这里只放稿面里的结构尺寸。
abstract final class SerialMetrics {
  static const double minWindow = 1180;
  static const double menuBar = 34;
  static const double statusBar = 30;
  static const double sidebar = 272;
  static const double tools = 352;
  static const double logHead = 36;
  static const double sendHeight = 104;
  static const double sendSide = 120;
  static const double control = 28;
  static const double controlSm = 26;
  static const double buttonSm = 24;
  static const double openButton = 32;
  static const double labelCol = 62;
  static const double searchWidth = 220;
  static const double dialogWidth = 640;
  static const double controlRadius = 4;
  static const double lamp = 12;
  static const double pin = 8;
  static const double statusLamp = 9;
  static const double formGap = 5;
  static const int logLimit = 500;
  static const int historyLimit = 12;
  static const int filePreviewBytes = 256;
  static const int minLoopMs = 10;
  static const int splitHintMs = 8;

  static const baudRates = [
    1200,
    2400,
    4800,
    9600,
    19200,
    38400,
    57600,
    115200,
    230400,
    460800,
    921600,
  ];

  static const groupPadding = EdgeInsets.fromLTRB(
    AppSpacing.md,
    7,
    AppSpacing.md,
    AppSpacing.sm,
  );
}
