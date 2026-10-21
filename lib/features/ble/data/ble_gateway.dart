import 'dart:typed_data';

import '../model/ble_models.dart';

/// 桌面 BLE 适配器。测试用假实现，不依赖系统蓝牙。
abstract class BleGateway {
  Stream<BleDeviceInfo> get scans;

  Stream<BleNotifyEvent> get notifications;

  /// true 已连接，false 断开；错误文案走 [errors]。
  Stream<bool> get connections;

  Stream<String> get errors;

  Future<bool> adapterReady();

  Future<void> startScan();

  Future<void> stopScan();

  /// 返回协商后的 MTU。
  Future<int> connect(String deviceId, {required int mtu});

  Future<void> disconnect();

  Future<List<BleServiceInfo>> discover();

  Future<void> setNotify({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enable,
  });

  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List data,
    required bool withResponse,
  });

  Future<void> dispose();
}
