import 'dart:async';
import 'dart:typed_data';

import '../model/ble_models.dart';
import 'ble_gateway.dart';

/// 组件测试或无适配器时的空实现。
class IdleBleGateway implements BleGateway {
  final _scans = StreamController<BleDeviceInfo>.broadcast();
  final _notifications = StreamController<BleNotifyEvent>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  @override
  Stream<BleDeviceInfo> get scans => _scans.stream;

  @override
  Stream<BleNotifyEvent> get notifications => _notifications.stream;

  @override
  Stream<bool> get connections => _connections.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  Future<bool> adapterReady() async => false;

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<int> connect(String deviceId, {required int mtu}) async {
    throw StateError('idle');
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<List<BleServiceInfo>> discover() async => const [];

  @override
  Future<void> setNotify({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enable,
  }) async {}

  @override
  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List data,
    required bool withResponse,
  }) async {}

  @override
  Future<void> dispose() async {
    await _scans.close();
    await _notifications.close();
    await _connections.close();
    await _errors.close();
  }
}
