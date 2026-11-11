import 'dart:io';

import 'package:device_debug_tools/core/storage/storage_keys.dart';
import 'package:device_debug_tools/features/mcp/cubit/mcp_cubit.dart';
import 'package:device_debug_tools/features/mcp/data/mcp_settings_store.dart';
import 'package:device_debug_tools/features/mcp/model/mcp_models.dart';
import 'package:device_debug_tools/features/mcp/repository/mcp_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ddt_mcp_license_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(StorageKeys.settingsBox);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
      await Hive.close();
    }
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('未激活时不监听，且保留已存 enabled', () async {
    final box = Hive.box<dynamic>(StorageKeys.settingsBox);
    final store = McpSettingsStore(box);
    await store.write(McpSettings.defaults.copyWith(enabled: true));

    final cubit = McpCubit(repository: McpRepository(store: store));
    await cubit.setLicenseActive(false);

    expect(cubit.licenseActive, isFalse);
    expect(cubit.state.settings.enabled, isTrue);
    expect(cubit.state.listening, isFalse);

    await cubit.setEnabled(true);
    expect(cubit.state.listening, isFalse);
    expect(cubit.state.settings.enabled, isTrue);

    await cubit.close();
  });

  test('激活后按已存开关拉起监听', () async {
    final box = Hive.box<dynamic>(StorageKeys.settingsBox);
    final store = McpSettingsStore(box);
    await store.write(
      McpSettings.defaults.copyWith(enabled: true, port: 39291),
    );

    final cubit = McpCubit(repository: McpRepository(store: store));
    await cubit.setLicenseActive(true);

    expect(cubit.licenseActive, isTrue);
    expect(cubit.state.listening, isTrue);
    expect(cubit.state.settings.enabled, isTrue);

    await cubit.setLicenseActive(false);
    expect(cubit.state.listening, isFalse);
    expect(cubit.state.settings.enabled, isTrue);

    await cubit.close();
  });
}
