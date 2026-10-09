import 'package:flutter/foundation.dart';

/// 开发环境标志，由 [bootstrap] 注入（`main_dev.dart`）。
bool appIsDev = false;

bool get appIsRelease => kReleaseMode;
