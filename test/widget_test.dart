import 'dart:io';

import 'package:device_debug_tools/app/cubit/app_cubit.dart';
import 'package:device_debug_tools/app/startup/bootstrap.dart';
import 'package:device_debug_tools/core/storage/storage_keys.dart';
import 'package:device_debug_tools/core/storage/user_prefs_storage.dart';
import 'package:device_debug_tools/features/serial/widget/serial_dialog.dart';
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

  testWidgets('文件菜单打开导出配置清单，全不勾时拦下', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildAppRoot(userPrefsStorage: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导出配置…'));
    await tester.pumpAndSettle();

    expect(find.text('导出配置'), findsOneWidget);
    final boxes = find.descendant(
      of: find.byType(SerialDialogFrame),
      matching: find.byType(Checkbox),
    );
    expect(boxes, findsNWidgets(4));
    for (var i = 0; i < 4; i++) {
      await tester.tap(boxes.at(i));
      await tester.pump();
    }
    await tester.tap(find.text('导出'));
    await tester.pump();
    expect(find.text('至少勾选一类'), findsOneWidget);
  });

  test('UserPrefsStorage 主题默认跟随系统并可持久化', () async {
    expect(prefs.readThemeMode(), ThemeMode.system);
    await prefs.saveThemeMode(ThemeMode.dark);
    expect(prefs.readThemeMode(), ThemeMode.dark);
  });
}
