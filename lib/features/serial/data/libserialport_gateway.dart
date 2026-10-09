import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../model/serial_models.dart';
import 'serial_line_control.dart';
import 'serial_native_text.dart';
import 'serial_port_gateway.dart';

class LibserialportGateway implements SerialPortGateway {
  LibserialportGateway() : _incoming = StreamController<Uint8List>.broadcast();

  final StreamController<Uint8List> _incoming;
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _readerSub;

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  bool get isOpen => _port?.isOpen ?? false;

  @override
  Future<List<SerialPortInfo>> listPorts() async {
    try {
      final names = SerialPort.availablePorts;
      final ports = <SerialPortInfo>[];
      for (final name in names) {
        final port = SerialPort(name);
        try {
          ports.add(SerialPortInfo(name: name, label: _label(port)));
        } finally {
          port.dispose();
        }
      }
      return ports;
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '扫描串口失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      throw DeviceException(decodeSerialNativeText('$error'));
    }
  }

  @override
  Future<SerialOpenResult> open(SerialLinkConfig config) async {
    await close();
    final port = SerialPort(config.portName);
    try {
      if (!port.openReadWrite()) {
        final err = SerialPort.lastError;
        throw DeviceException(
          serialOsErrorDetail(code: err?.errorCode, message: err?.message),
        );
      }
      _port = port;
      var result = SerialOpenResult.full;
      try {
        await apply(config);
      } on DeviceException catch (error) {
        if (!Platform.isWindows) {
          throw DeviceConfigException(error.message);
        }
        AppLogger.i.error(
          '完整串口参数未生效，尝试仅写入帧格式',
          category: LogCategory.device,
          error: error,
        );
        try {
          await apply(config, applyLines: false);
          result = SerialOpenResult.partial;
        } on DeviceException catch (retryError) {
          throw DeviceConfigException(retryError.message);
        }
      }
      _reader = SerialPortReader(port);
      _readerSub = _reader!.stream.listen(
        _incoming.add,
        onError: _incoming.addError,
      );
      return result;
    } catch (error, stackTrace) {
      if (identical(_port, port)) {
        await close();
      } else {
        try {
          if (port.isOpen) port.close();
        } catch (_) {}
        port.dispose();
      }
      if (error is DeviceException) rethrow;
      AppLogger.i.error(
        '打开串口失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      throw DeviceException(serialOsErrorDetail(message: '$error'));
    }
  }

  @override
  Future<void> apply(
    SerialLinkConfig config, {
    bool applyLines = true,
  }) async {
    final port = _port;
    if (port == null || !port.isOpen) {
      throw DeviceException('port closed');
    }
    final cfg = SerialPortConfig();
    try {
      cfg.baudRate = config.baud;
      cfg.bits = config.dataBits;
      cfg.parity = switch (config.parity) {
        Parity.none => SerialPortParity.none,
        Parity.odd => SerialPortParity.odd,
        Parity.even => SerialPortParity.even,
        Parity.mark => SerialPortParity.mark,
        Parity.space => SerialPortParity.space,
      };
      cfg.stopBits = config.stopBits.wireValue;
      cfg.setFlowControl(switch (config.flow) {
        FlowControl.none => SerialPortFlowControl.none,
        FlowControl.xonXoff => SerialPortFlowControl.xonXoff,
        FlowControl.rtsCts => SerialPortFlowControl.rtsCts,
        FlowControl.dtrDsr => SerialPortFlowControl.dtrDsr,
      });
      if (applyLines) {
        _writeLines(cfg, config);
      }
      port.config = cfg;
    } on SerialPortError catch (error, stackTrace) {
      AppLogger.i.error(
        '串口参数未生效',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      throw DeviceException(decodeSerialNativeText(error.message));
    } finally {
      cfg.dispose();
    }
  }

  void _writeLines(SerialPortConfig cfg, SerialLinkConfig config) {
    final win = Platform.isWindows;
    if (config.flow != FlowControl.rtsCts) {
      final rts = serialLineControlValue(on: config.rts, isWindows: win);
      if (rts != null) {
        cfg.rts = rts ? SerialPortRts.on : SerialPortRts.off;
      }
    }
    if (config.flow != FlowControl.dtrDsr) {
      final dtr = serialLineControlValue(on: config.dtr, isWindows: win);
      if (dtr != null) {
        cfg.dtr = dtr ? SerialPortDtr.on : SerialPortDtr.off;
      }
    }
  }

  @override
  Future<void> write(Uint8List data) async {
    final port = _port;
    if (port == null || !port.isOpen) {
      throw DeviceException('port closed');
    }
    try {
      port.write(data);
    } on SerialPortError catch (error, stackTrace) {
      AppLogger.i.error(
        '串口写入失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      throw DeviceException(decodeSerialNativeText(error.message));
    }
  }

  @override
  PinLevels readPins() {
    final port = _port;
    if (port == null || !port.isOpen) return const PinLevels();
    try {
      final bits = port.signals;
      return PinLevels(
        cts: (bits & SerialPortSignal.cts) != 0,
        dsr: (bits & SerialPortSignal.dsr) != 0,
        dcd: (bits & SerialPortSignal.dcd) != 0,
        ri: (bits & SerialPortSignal.ri) != 0,
      );
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '读取引脚失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      return const PinLevels();
    }
  }

  @override
  Future<void> close() async {
    await _readerSub?.cancel();
    _readerSub = null;
    _reader?.close();
    _reader = null;
    final port = _port;
    _port = null;
    if (port == null) return;
    try {
      if (port.isOpen) port.close();
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '关闭串口失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      port.dispose();
    }
  }

  String _label(SerialPort port) {
    final name = port.name ?? '';
    final raw = port.description ?? port.productName ?? port.manufacturer;
    final desc = raw == null ? null : decodeSerialNativeText(raw);
    if (desc == null || desc.isEmpty || desc == name) return name;
    return '$name · $desc';
  }
}
