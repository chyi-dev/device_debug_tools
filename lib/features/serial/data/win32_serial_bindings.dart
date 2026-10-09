import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'serial_native_text.dart';

/// Win32 串口原语；生产环境用 [NativeWin32SerialBindings]，测试可注入假实现。
abstract class Win32SerialBindings {
  /// 成功返回句柄地址；失败返回 null，[lastError] 为原因。
  int? createFile(String devicePath);

  bool closeHandle(int handle);

  bool getCommState(int handle, Pointer<DCB> dcb);

  bool setCommState(int handle, Pointer<DCB> dcb);

  bool setCommTimeouts(int handle, Pointer<COMMTIMEOUTS> timeouts);

  bool escapeComm(int handle, int func);

  bool getModemStatus(int handle, Pointer<Uint32> status);

  int write(int handle, Uint8List data);

  Uint8List readAvailable(int handle, int maxLen);

  int get lastError;

  String messageForError(int code);
}

class NativeWin32SerialBindings implements Win32SerialBindings {
  int _lastError = 0;

  @override
  int get lastError => _lastError;

  @override
  String messageForError(int code) {
    if (code == 0) return serialOsErrorDetail(code: 0);
    try {
      final text = WIN32_ERROR(code).toHRESULT().message.trim();
      return serialOsErrorDetail(code: code, message: text);
    } catch (_) {
      return serialOsErrorDetail(code: code);
    }
  }

  @override
  int? createFile(String devicePath) {
    final path = PCWSTR(devicePath.toNativeUtf16());
    try {
      final result = CreateFile(
        path,
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_NONE,
        null,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        null,
      );
      _lastError = result.error;
      final handle = result.value;
      if (!handle.isValid) return null;
      return handle.address;
    } finally {
      calloc.free(path);
    }
  }

  HANDLE _h(int handle) => HANDLE(Pointer.fromAddress(handle));

  @override
  bool closeHandle(int handle) {
    final result = CloseHandle(_h(handle));
    _lastError = result.error;
    return result.value;
  }

  @override
  bool getCommState(int handle, Pointer<DCB> dcb) {
    final result = GetCommState(_h(handle), dcb);
    _lastError = result.error;
    return result.value;
  }

  @override
  bool setCommState(int handle, Pointer<DCB> dcb) {
    final result = SetCommState(_h(handle), dcb);
    _lastError = result.error;
    return result.value;
  }

  @override
  bool setCommTimeouts(int handle, Pointer<COMMTIMEOUTS> timeouts) {
    final result = SetCommTimeouts(_h(handle), timeouts);
    _lastError = result.error;
    return result.value;
  }

  @override
  bool escapeComm(int handle, int func) {
    final result = EscapeCommFunction(_h(handle), ESCAPE_COMM_FUNCTION(func));
    _lastError = result.error;
    return result.value;
  }

  @override
  bool getModemStatus(int handle, Pointer<Uint32> status) {
    final result = GetCommModemStatus(_h(handle), status);
    _lastError = result.error;
    return result.value;
  }

  @override
  int write(int handle, Uint8List data) {
    if (data.isEmpty) return 0;
    return using((arena) {
      final buf = arena<Uint8>(data.length);
      buf.asTypedList(data.length).setAll(0, data);
      final written = arena<Uint32>();
      final result = WriteFile(_h(handle), buf, data.length, written, null);
      _lastError = result.error;
      if (!result.value) {
        throw StateError(messageForError(_lastError));
      }
      return written.value;
    });
  }

  @override
  Uint8List readAvailable(int handle, int maxLen) {
    if (maxLen <= 0) return Uint8List(0);
    return using((arena) {
      final buf = arena<Uint8>(maxLen);
      final read = arena<Uint32>();
      final result = ReadFile(_h(handle), buf, maxLen, read, null);
      _lastError = result.error;
      if (!result.value) {
        // 超时/无数据时部分驱动返回失败但字节为 0，视为空读。
        if (read.value == 0) return Uint8List(0);
        throw StateError(messageForError(_lastError));
      }
      final n = read.value;
      if (n <= 0) return Uint8List(0);
      return Uint8List.fromList(buf.asTypedList(n));
    });
  }
}
