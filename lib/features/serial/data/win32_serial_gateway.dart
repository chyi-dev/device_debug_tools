import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:win32/win32.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../model/serial_models.dart';
import 'serial_native_text.dart';
import 'serial_port_gateway.dart';
import 'win32_serial_bindings.dart';

/// Windows 专用串口网关：CreateFile 成功即视为打开；SetCommState 失败可降级。
class Win32SerialGateway implements SerialPortGateway {
  Win32SerialGateway({Win32SerialBindings? bindings})
      : _api = bindings ?? NativeWin32SerialBindings(),
        _incoming = StreamController<Uint8List>.broadcast();

  final Win32SerialBindings _api;
  final StreamController<Uint8List> _incoming;
  int? _handle;
  Timer? _reader;

  static const _maxRead = 4096;
  static const _pollMs = 20;

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  bool get isOpen => _handle != null;

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
    final path = _devicePath(config.portName);
    final handle = _api.createFile(path);
    if (handle == null) {
      throw DeviceException(
        serialOsErrorDetail(
          code: _api.lastError,
          message: _api.messageForError(_api.lastError),
        ),
      );
    }
    _handle = handle;
    try {
      _applyTimeouts(handle);
      final configured = _configure(handle, config);
      _applyLines(handle, config);
      _startReader();
      return configured ? SerialOpenResult.full : SerialOpenResult.partial;
    } catch (error, stackTrace) {
      await close();
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
  Future<void> apply(SerialLinkConfig config) async {
    final handle = _handle;
    if (handle == null) throw DeviceException('port closed');
    final ok = _configure(handle, config);
    _applyLines(handle, config);
    if (!ok) {
      throw DeviceConfigException(
        serialOsErrorDetail(
          code: _api.lastError,
          message: _api.messageForError(_api.lastError),
        ),
      );
    }
  }

  @override
  Future<void> write(Uint8List data) async {
    final handle = _handle;
    if (handle == null) throw DeviceException('port closed');
    try {
      _api.write(handle, data);
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '串口写入失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      throw DeviceException(serialOsErrorDetail(message: '$error'));
    }
  }

  @override
  PinLevels readPins() {
    final handle = _handle;
    if (handle == null) return const PinLevels();
    return using((arena) {
      final status = arena<Uint32>();
      if (!_api.getModemStatus(handle, status)) return const PinLevels();
      final bits = status.value;
      return PinLevels(
        cts: (bits & MS_CTS_ON) != 0,
        dsr: (bits & MS_DSR_ON) != 0,
        dcd: (bits & MS_RLSD_ON) != 0,
        ri: (bits & MS_RING_ON) != 0,
      );
    });
  }

  @override
  Future<void> close() async {
    _reader?.cancel();
    _reader = null;
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    try {
      _api.closeHandle(handle);
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '关闭串口失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _devicePath(String name) {
    final trimmed = name.trim();
    if (trimmed.startsWith('\\\\.\\') || trimmed.startsWith('\\\\?\\')) {
      return trimmed;
    }
    return '\\\\.\\$trimmed';
  }

  void _applyTimeouts(int handle) {
    using((arena) {
      final t = arena<COMMTIMEOUTS>();
      // 读立即返回已缓冲数据；写最多等待 2s。
      t.ref
        ..ReadIntervalTimeout = 0xFFFFFFFF
        ..ReadTotalTimeoutMultiplier = 0
        ..ReadTotalTimeoutConstant = 0
        ..WriteTotalTimeoutMultiplier = 0
        ..WriteTotalTimeoutConstant = 2000;
      if (!_api.setCommTimeouts(handle, t)) {
        AppLogger.i.error(
          'SetCommTimeouts 失败',
          category: LogCategory.device,
          error: _api.messageForError(_api.lastError),
        );
      }
    });
  }

  /// 配置 DCB；返回 SetCommState 是否成功。失败不关口。
  bool _configure(int handle, SerialLinkConfig config) {
    return using((arena) {
      final dcb = arena<DCB>();
      dcb.ref.DCBlength = sizeOf<DCB>();
      if (!_api.getCommState(handle, dcb)) {
        AppLogger.i.error(
          'GetCommState 失败',
          category: LogCategory.device,
          error: _api.messageForError(_api.lastError),
        );
        return false;
      }
      dcb.ref
        ..BaudRate = config.baud
        ..ByteSize = config.dataBits
        ..fBinary = 1
        ..fParity = config.parity == Parity.none ? 0 : 1
        ..fAbortOnError = 0
        ..fNull = 0
        ..fErrorChar = 0
        ..Parity = switch (config.parity) {
          Parity.none => NOPARITY,
          Parity.odd => ODDPARITY,
          Parity.even => EVENPARITY,
          Parity.mark => MARKPARITY,
          Parity.space => SPACEPARITY,
        }
        ..StopBits = switch (config.stopBits) {
          StopBits.one => ONESTOPBIT,
          StopBits.oneHalf => ONE5STOPBITS,
          StopBits.two => TWOSTOPBITS,
        };

      switch (config.flow) {
        case FlowControl.none:
          dcb.ref
            ..fOutxCtsFlow = 0
            ..fOutxDsrFlow = 0
            ..fInX = 0
            ..fOutX = 0
            ..fRtsControl = RTS_CONTROL_ENABLE
            ..fDtrControl = DTR_CONTROL_ENABLE;
        case FlowControl.xonXoff:
          dcb.ref
            ..fOutxCtsFlow = 0
            ..fOutxDsrFlow = 0
            ..fInX = 1
            ..fOutX = 1
            ..fRtsControl = RTS_CONTROL_ENABLE
            ..fDtrControl = DTR_CONTROL_ENABLE;
        case FlowControl.rtsCts:
          dcb.ref
            ..fOutxCtsFlow = 1
            ..fOutxDsrFlow = 0
            ..fInX = 0
            ..fOutX = 0
            ..fRtsControl = RTS_CONTROL_HANDSHAKE
            ..fDtrControl = DTR_CONTROL_ENABLE;
        case FlowControl.dtrDsr:
          dcb.ref
            ..fOutxCtsFlow = 0
            ..fOutxDsrFlow = 1
            ..fInX = 0
            ..fOutX = 0
            ..fRtsControl = RTS_CONTROL_ENABLE
            ..fDtrControl = DTR_CONTROL_HANDSHAKE;
      }

      final ok = _api.setCommState(handle, dcb);
      if (!ok) {
        AppLogger.i.error(
          'SetCommState 失败，保留句柄继续通信',
          category: LogCategory.device,
          error: _api.messageForError(_api.lastError),
        );
      }
      return ok;
    });
  }

  void _applyLines(int handle, SerialLinkConfig config) {
    if (config.flow != FlowControl.dtrDsr) {
      _api.escapeComm(handle, (config.dtr ? SETDTR : CLRDTR) as int);
    }
    if (config.flow != FlowControl.rtsCts) {
      _api.escapeComm(handle, (config.rts ? SETRTS : CLRRTS) as int);
    }
  }

  void _startReader() {
    _reader?.cancel();
    _reader = Timer.periodic(const Duration(milliseconds: _pollMs), (_) {
      final handle = _handle;
      if (handle == null) return;
      try {
        final chunk = _api.readAvailable(handle, _maxRead);
        if (chunk.isNotEmpty) _incoming.add(chunk);
      } catch (error, stackTrace) {
        AppLogger.i.error(
          '串口读取中断',
          category: LogCategory.device,
          error: error,
          stackTrace: stackTrace,
        );
        _incoming.addError(error, stackTrace);
        unawaited(close());
      }
    });
  }

  String _label(SerialPort port) {
    final name = port.name ?? '';
    final raw = port.description ?? port.productName ?? port.manufacturer;
    final desc = raw == null ? null : decodeSerialNativeText(raw);
    if (desc == null || desc.isEmpty || desc == name) return name;
    return '$name · $desc';
  }
}
