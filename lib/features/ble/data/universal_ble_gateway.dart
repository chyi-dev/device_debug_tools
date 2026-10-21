import 'dart:async';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../model/ble_models.dart';
import 'ble_gateway.dart';

class UniversalBleGateway implements BleGateway {
  UniversalBleGateway() {
    UniversalBle.onScanResult = _onScan;
    UniversalBle.onValueChange = _onValue;
    UniversalBle.onConnectionChange = _onConnection;
  }

  final _scans = StreamController<BleDeviceInfo>.broadcast();
  final _notifications = StreamController<BleNotifyEvent>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  String? _deviceId;
  var _disposed = false;

  @override
  Stream<BleDeviceInfo> get scans => _scans.stream;

  @override
  Stream<BleNotifyEvent> get notifications => _notifications.stream;

  @override
  Stream<bool> get connections => _connections.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  Future<bool> adapterReady() async {
    try {
      final state = await UniversalBle.getBluetoothAvailabilityState();
      return state == AvailabilityState.poweredOn;
    } catch (error, stackTrace) {
      _log('读取蓝牙适配器失败', error, stackTrace);
      return false;
    }
  }

  @override
  Future<void> startScan() async {
    try {
      await UniversalBle.startScan();
    } catch (error, stackTrace) {
      _log('BLE 扫描失败', error, stackTrace);
      throw DeviceException('$error');
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await UniversalBle.stopScan();
    } catch (error, stackTrace) {
      _log('停止 BLE 扫描失败', error, stackTrace);
    }
  }

  @override
  Future<int> connect(String deviceId, {required int mtu}) async {
    _deviceId = deviceId;
    try {
      await UniversalBle.connect(deviceId);
      try {
        return await UniversalBle.requestMtu(deviceId, mtu);
      } catch (error, stackTrace) {
        _log('请求 MTU 失败，使用请求值', error, stackTrace);
        return mtu;
      }
    } catch (error, stackTrace) {
      _deviceId = null;
      _log('BLE 连接失败', error, stackTrace);
      throw DeviceException('$error');
    }
  }

  @override
  Future<void> disconnect() async {
    final id = _deviceId;
    _deviceId = null;
    if (id == null) return;
    try {
      await UniversalBle.disconnect(id);
    } catch (error, stackTrace) {
      _log('BLE 断开失败', error, stackTrace);
    }
  }

  @override
  Future<List<BleServiceInfo>> discover() async {
    final id = _deviceId;
    if (id == null) return const [];
    try {
      final services = await UniversalBle.discoverServices(id);
      return [
        for (final service in services)
          BleServiceInfo(
            uuid: _uuid(service.uuid),
            name: _serviceName(service.uuid),
            characteristics: [
              for (final char in service.characteristics)
                BleCharacteristicInfo(
                  uuid: _uuid(char.uuid),
                  serviceUuid: _uuid(service.uuid),
                  name: _charName(char.uuid),
                  canNotify:
                      char.properties.contains(CharacteristicProperty.notify) ||
                      char.properties.contains(CharacteristicProperty.indicate),
                  canWrite: char.properties.contains(
                    CharacteristicProperty.write,
                  ),
                  canWriteWithoutResponse: char.properties.contains(
                    CharacteristicProperty.writeWithoutResponse,
                  ),
                  canRead: char.properties.contains(
                    CharacteristicProperty.read,
                  ),
                ),
            ],
          ),
      ];
    } catch (error, stackTrace) {
      _log('发现 GATT 失败', error, stackTrace);
      throw DeviceException('$error');
    }
  }

  @override
  Future<void> setNotify({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enable,
  }) async {
    final id = _deviceId;
    if (id == null) return;
    try {
      if (enable) {
        try {
          await UniversalBle.subscribeNotifications(
            id,
            serviceUuid,
            characteristicUuid,
          );
        } catch (error, stackTrace) {
          _log('订阅 Notify 失败，改用 Indicate', error, stackTrace);
          await UniversalBle.subscribeIndications(
            id,
            serviceUuid,
            characteristicUuid,
          );
        }
      } else {
        await UniversalBle.unsubscribe(id, serviceUuid, characteristicUuid);
      }
    } catch (error, stackTrace) {
      _log('设置通知失败', error, stackTrace);
      throw DeviceException('$error');
    }
  }

  @override
  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List data,
    required bool withResponse,
  }) async {
    final id = _deviceId;
    if (id == null) throw DeviceException('未连接');
    try {
      await UniversalBle.write(
        id,
        serviceUuid,
        characteristicUuid,
        data,
        withoutResponse: !withResponse,
      );
    } catch (error, stackTrace) {
      _log('BLE 写入失败', error, stackTrace);
      throw DeviceException('$error');
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stopScan();
    await disconnect();
    UniversalBle.onScanResult = null;
    UniversalBle.onValueChange = null;
    UniversalBle.onConnectionChange = null;
    await _scans.close();
    await _notifications.close();
    await _connections.close();
    await _errors.close();
  }

  void _onScan(BleDevice device) {
    if (_disposed) return;
    _scans.add(
      BleDeviceInfo(
        id: device.deviceId,
        name: device.name ?? '',
        address: device.deviceId,
        rssi: device.rssi ?? 0,
      ),
    );
  }

  void _onValue(String deviceId, String characteristicId, Uint8List value) {
    if (_disposed) return;
    _notifications.add(
      BleNotifyEvent(
        deviceId: deviceId,
        serviceUuid: '',
        characteristicUuid: _uuid(characteristicId),
        value: value,
      ),
    );
  }

  void _onConnection(String deviceId, bool connected, String? error) {
    if (_disposed) return;
    if (!connected) _deviceId = null;
    _connections.add(connected);
    if (error != null && error.isNotEmpty) _errors.add(error);
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    AppLogger.i.error(
      message,
      category: LogCategory.device,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

String _uuid(String raw) {
  final text = raw.replaceAll('-', '').toUpperCase();
  if (text.length == 4) return text;
  if (text.length == 32 && text.startsWith('0000') && text.endsWith('00001000800000805F9B34FB')) {
    return text.substring(4, 8);
  }
  return raw.toUpperCase();
}

String _serviceName(String uuid) {
  final short = _uuid(uuid);
  return switch (short) {
    '180A' => 'Device Information',
    '180F' => 'Battery',
    'FFF0' => '透传',
    _ => '',
  };
}

String _charName(String uuid) {
  final short = _uuid(uuid);
  return switch (short) {
    '2A29' => 'Manufacturer Name',
    '2A24' => 'Model Number',
    '2A19' => 'Battery Level',
    'FFF1' => 'TX Notify',
    'FFF2' => 'RX Write',
    _ => '',
  };
}
