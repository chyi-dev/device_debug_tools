import 'dart:typed_data';

import '../model/serial_models.dart';

abstract class SerialPortGateway {
  Future<List<SerialPortInfo>> listPorts();

  /// 打开串口并应用参数。成功返回 [SerialOpenResult]；
  /// 句柄打不开抛 [DeviceException]；口已开但参数全失败抛 [DeviceConfigException]。
  Future<SerialOpenResult> open(SerialLinkConfig config);

  Future<void> apply(SerialLinkConfig config);

  Future<void> write(Uint8List data);

  Stream<Uint8List> get incoming;

  PinLevels readPins();

  Future<void> close();

  bool get isOpen;
}
