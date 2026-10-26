import 'package:device_debug_tools/app/theme/app_theme.dart';
import 'package:device_debug_tools/features/mqtt/cubit/mqtt_console_cubit.dart';
import 'package:device_debug_tools/features/mqtt/data/mqtt_file_gateway.dart';
import 'package:device_debug_tools/features/mqtt/data/mqtt_gateway.dart';
import 'package:device_debug_tools/features/mqtt/data/mqtt_workspace_store.dart';
import 'package:device_debug_tools/features/mqtt/model/mqtt_models.dart';
import 'package:device_debug_tools/features/mqtt/repository/mqtt_console_repository.dart';
import 'package:device_debug_tools/features/mqtt/widget/mqtt_side_panel.dart';
import 'package:device_debug_tools/features/serial/data/serial_file_gateway.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:device_debug_tools/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_client/mqtt_client.dart';

void main() {
  late MqttConsoleCubit cubit;

  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.zh);
    cubit = MqttConsoleCubit(
      repository: MqttConsoleRepository(
        gateway: _FakeGateway(),
        store: _MemoryStore(),
        files: MqttFileGateway(files: _FakeFiles()),
      ),
    );
    await cubit.start();
    cubit.patch(settingsOpen: true);
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets('Client ID 保留下划线和特殊字符', (tester) async {
    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    const clientId = r'device_01@lab#1$%&*()[]{}:;,./\-+';
    final field = find.widgetWithText(TextField, 'ddt-desktop-01');
    expect(field, findsOneWidget);
    await tester.enterText(field, clientId);
    await tester.pump();

    expect(cubit.state.clientId, clientId);
    expect(find.widgetWithText(TextField, clientId), findsOneWidget);

    final restored = MqttWorkspace.fromJson(cubit.state.toWorkspace().toJson());
    expect(restored.clientId, clientId);

    expect(
      () => MqttConnectMessage().withClientIdentifier(clientId),
      returnsNormally,
    );

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(cubit.state.clientId, clientId);
    await tester.pump(const Duration(milliseconds: 500));
  });
}

Widget _app(MqttConsoleCubit cubit) {
  return TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<MqttConsoleCubit>.value(
        value: cubit,
        child: const Scaffold(
          body: SizedBox(width: 272, child: MqttSidePanel()),
        ),
      ),
    ),
  );
}

class _FakeGateway implements MqttGateway {
  @override
  Stream<MqttIncoming> get messages => const Stream.empty();

  @override
  Stream<bool> get connections => const Stream.empty();

  @override
  Stream<String> get errors => const Stream.empty();

  @override
  bool get isConnected => false;

  @override
  Future<void> connect(MqttLinkConfig config) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> subscribe(String topic, int qos) async {}

  @override
  Future<void> unsubscribe(String topic) async {}

  @override
  Future<void> publish({
    required String topic,
    required String payload,
    required int qos,
    required bool retain,
  }) async {}

  @override
  Future<void> dispose() async {}
}

class _MemoryStore implements MqttWorkspaceStore {
  @override
  MqttWorkspace? read() => null;

  @override
  Future<void> write(MqttWorkspace workspace) async {}
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
