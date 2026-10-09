import 'dart:io';

import 'package:device_debug_tools/app/cubit/app_cubit.dart';
import 'package:device_debug_tools/app/startup/bootstrap.dart';
import 'package:device_debug_tools/core/storage/storage_keys.dart';
import 'package:device_debug_tools/core/storage/user_prefs_storage.dart';
import 'package:device_debug_tools/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late UserPrefsStorage prefs;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ddt_test_');
    Hive.init(tempDir.path);
    final box = await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    prefs = UserPrefsStorage(box);
    await LocaleSettings.setLocale(AppLocale.zh);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('应用启动后渲染首页', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildAppRoot(userPrefsStorage: prefs));
    await tester.pumpAndSettle();

    expect(find.text('串口设置'), findsOneWidget);
    expect(find.text('数据日志'), findsOneWidget);
  });

  testWidgets('AppCubit 切换语言后界面刷新并持久化', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildAppRoot(userPrefsStorage: prefs));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('文件'));
    await tester.runAsync(
      () => context.read<AppCubit>().setLocale(AppLocale.en),
    );
    await tester.pumpAndSettle();

    expect(find.text('File'), findsOneWidget);
    expect(prefs.readLocale(), 'en');
  });

  test('UserPrefsStorage 主题默认跟随系统并可持久化', () async {
    expect(prefs.readThemeMode(), ThemeMode.system);
    await prefs.saveThemeMode(ThemeMode.dark);
    expect(prefs.readThemeMode(), ThemeMode.dark);
  });
}
