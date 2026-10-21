import 'dart:typed_data';

import '../../serial/data/serial_file_gateway.dart';
import '../data/ble_gateway.dart';
import '../data/ble_workspace_store.dart';
import '../model/ble_models.dart';

class BleConsoleRepository {
  BleConsoleRepository({
    required BleGateway gateway,
    required BleWorkspaceStore store,
    required SerialFileGateway files,
  }) : _gateway = gateway,
       _store = store,
       _files = files;

  final BleGateway _gateway;
  final BleWorkspaceStore _store;
  final SerialFileGateway _files;

  BleGateway get gateway => _gateway;

  BleWorkspace? load() => _store.read();

  Future<void> save(BleWorkspace workspace) => _store.write(workspace);

  Stream<BleDeviceInfo> get scans => _gateway.scans;

  Stream<BleNotifyEvent> get notifications => _gateway.notifications;

  Stream<bool> get connections => _gateway.connections;

  Stream<String> get errors => _gateway.errors;

  Future<bool> adapterReady() => _gateway.adapterReady();

  Future<void> startScan() => _gateway.startScan();

  Future<void> stopScan() => _gateway.stopScan();

  Future<int> connect(String deviceId, {required int mtu}) =>
      _gateway.connect(deviceId, mtu: mtu);

  Future<void> disconnect() => _gateway.disconnect();

  Future<List<BleServiceInfo>> discover() => _gateway.discover();

  Future<void> setNotify({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enable,
  }) => _gateway.setNotify(
    serviceUuid: serviceUuid,
    characteristicUuid: characteristicUuid,
    enable: enable,
  );

  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List data,
    required bool withResponse,
  }) => _gateway.write(
    serviceUuid: serviceUuid,
    characteristicUuid: characteristicUuid,
    data: data,
    withResponse: withResponse,
  );

  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) => _files.pickSave(suggestedName: suggestedName, extension: extension);

  Future<void> writeText({required String path, required String text}) =>
      _files.writeText(path: path, text: text);

  Future<void> close() => _gateway.dispose();
}
