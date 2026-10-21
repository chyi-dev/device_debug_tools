import 'package:device_debug_tools/app/theme/app_theme.dart';
import 'package:device_debug_tools/features/ble/cubit/ble_console_cubit.dart';
import 'package:device_debug_tools/features/ble/data/ble_workspace_store.dart';
import 'package:device_debug_tools/features/ble/data/idle_ble_gateway.dart';
import 'package:device_debug_tools/features/ble/model/ble_models.dart';
import 'package:device_debug_tools/features/ble/repository/ble_console_repository.dart';
import 'package:device_debug_tools/features/ble/widget/ble_status_bar.dart';
import 'package:device_debug_tools/features/serial/data/serial_file_gateway.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:device_debug_tools/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BleConsoleCubit cubit;

  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.zh);
    cubit = BleConsoleCubit(
      repository: BleConsoleRepository(
        gateway: IdleBleGateway(),
        store: _MemoryStore(),
        files: _FakeFiles(),
      ),
    );
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets('长提示在状态栏内省略，不横向溢出', (tester) async {
    cubit.emit(
      cubit.state.copyWith(
        hint: BleNotice(
          id: 1,
          kind: BleNoticeKind.scanFailed,
          args: {'detail': 'X' * 400},
        ),
      ),
    );
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider<BleConsoleCubit>.value(
            value: cubit,
            child: const Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(width: 800, child: BleStatusBar()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(BleStatusBar), findsOneWidget);
  });
}

class _MemoryStore implements BleWorkspaceStore {
  @override
  BleWorkspace? read() => null;

  @override
  Future<void> write(BleWorkspace workspace) async {}
}

class _FakeFiles implements SerialFileGateway {
  @override
  Future<PickedBytes?> pickAny() async => null;

  @override
  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) async => null;

  @override
  Future<String?> pickText({required List<String> extensions}) async => null;

  @override
  Future<void> writeText({required String path, required String text}) async {}
}
