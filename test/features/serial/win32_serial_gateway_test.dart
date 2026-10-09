import 'dart:ffi';
import 'dart:typed_data';

import 'package:device_debug_tools/core/exception/app_exception.dart';
import 'package:device_debug_tools/features/serial/data/win32_serial_bindings.dart';
import 'package:device_debug_tools/features/serial/data/win32_serial_gateway.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:win32/win32.dart';

void main() {
  const link = SerialLinkConfig(
    portName: 'COM3',
    baud: 115200,
    parity: Parity.none,
    dataBits: 8,
    stopBits: StopBits.one,
    flow: FlowControl.none,
    dtr: true,
    rts: true,
  );

  test('CreateFile 失败抛 DeviceException', () async {
    final api = _FakeBindings()..createOk = false;
    final gateway = Win32SerialGateway(bindings: api);
    await expectLater(gateway.open(link), throwsA(isA<DeviceException>()));
    expect(gateway.isOpen, isFalse);
  });

  test('CreateFile 成功且 SetCommState 失败时仍打开并返回 partial', () async {
    final api = _FakeBindings()
      ..createOk = true
      ..setCommOk = false;
    final gateway = Win32SerialGateway(bindings: api);
    final result = await gateway.open(link);
    expect(result, SerialOpenResult.partial);
    expect(gateway.isOpen, isTrue);
    expect(api.handle, isNotNull);
    await gateway.close();
    expect(gateway.isOpen, isFalse);
    expect(api.handle, isNull);
  });

  test('CreateFile 与 SetCommState 均成功返回 full', () async {
    final api = _FakeBindings();
    final gateway = Win32SerialGateway(bindings: api);
    final result = await gateway.open(link);
    expect(result, SerialOpenResult.full);
    expect(gateway.isOpen, isTrue);
    await gateway.close();
  });
}

class _FakeBindings implements Win32SerialBindings {
  var createOk = true;
  var setCommOk = true;
  int? handle;
  var _last = 0;

  @override
  int get lastError => _last;

  @override
  String messageForError(int code) => code == 0 ? '无法打开串口' : 'err:$code';

  @override
  int? createFile(String devicePath) {
    if (!createOk) {
      _last = 2;
      return null;
    }
    handle = 0x1000;
    _last = 0;
    return handle;
  }

  @override
  bool closeHandle(int h) {
    handle = null;
    return true;
  }

  @override
  bool getCommState(int h, Pointer<DCB> dcb) {
    dcb.ref
      ..DCBlength = sizeOf<DCB>()
      ..BaudRate = 9600
      ..ByteSize = 8
      ..fBinary = 1
      ..Parity = NOPARITY
      ..StopBits = ONESTOPBIT
      ..fRtsControl = RTS_CONTROL_ENABLE
      ..fDtrControl = DTR_CONTROL_ENABLE;
    return true;
  }

  @override
  bool setCommState(int h, Pointer<DCB> dcb) {
    if (!setCommOk) {
      _last = 31;
      return false;
    }
    _last = 0;
    return true;
  }

  @override
  bool setCommTimeouts(int h, Pointer<COMMTIMEOUTS> timeouts) => true;

  @override
  bool escapeComm(int h, int func) => true;

  @override
  bool getModemStatus(int h, Pointer<Uint32> status) {
    status.value = 0;
    return true;
  }

  @override
  int write(int h, Uint8List data) => data.length;

  @override
  Uint8List readAvailable(int h, int maxLen) => Uint8List(0);
}
