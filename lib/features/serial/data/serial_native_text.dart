import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// 还原 libserialport 在 Windows 上经 Latin-1 误读的系统 ANSI 文本。
///
/// `sp_last_error_message` / 端口描述等在 Windows 使用 `FormatMessageA` 或
/// `WideCharToMultiByte(CP_ACP)`，Dart 绑定 UTF-8 失败后会按 Latin-1 解码，
/// 中文系统下表现为乱码。此处按当前 ACP 转回 Unicode。
String decodeSerialNativeText(String text) {
  if (text.isEmpty || !Platform.isWindows) return text;
  for (final unit in text.codeUnits) {
    if (unit > 0xFF) return text;
  }
  final bytes = latin1.encode(text);
  if (bytes.every((b) => b < 0x80)) return text;
  return _winAcpToString(bytes) ?? text;
}

/// 串口失败详情；过滤 Win32 错误码 0 /「操作成功完成」等假成功文案。
String serialOsErrorDetail({int? code, String? message}) {
  final raw = (message ?? '').trim();
  final decoded = raw.isEmpty ? '' : decodeSerialNativeText(raw);
  if (_looksLikeSuccess(code: code, message: decoded)) {
    return '无法打开串口';
  }
  if (decoded.isEmpty) return '无法打开串口';
  return decoded;
}

bool _looksLikeSuccess({int? code, required String message}) {
  if (code == 0) return true;
  final lower = message.toLowerCase();
  return message == '操作成功完成' ||
      lower == 'the operation completed successfully' ||
      lower == 'the operation completed successfully.';
}

typedef _MultiByteToWideCharNative =
    Int32 Function(
      Uint32 codePage,
      Uint32 dwFlags,
      Pointer<Uint8> lpMultiByteStr,
      Int32 cbMultiByte,
      Pointer<Utf16> lpWideCharStr,
      Int32 cchWideChar,
    );
typedef _MultiByteToWideCharDart =
    int Function(
      int codePage,
      int dwFlags,
      Pointer<Uint8> lpMultiByteStr,
      int cbMultiByte,
      Pointer<Utf16> lpWideCharStr,
      int cchWideChar,
    );

typedef _GetAcpNative = Uint32 Function();
typedef _GetAcpDart = int Function();

const _cpAcp = 0;

DynamicLibrary? _kernel32;
_MultiByteToWideCharDart? _multiByteToWideChar;
_GetAcpDart? _getAcp;

void _ensureKernel32() {
  if (_kernel32 != null) return;
  final lib = DynamicLibrary.open('kernel32.dll');
  _kernel32 = lib;
  _multiByteToWideChar = lib
      .lookupFunction<_MultiByteToWideCharNative, _MultiByteToWideCharDart>(
        'MultiByteToWideChar',
      );
  _getAcp = lib.lookupFunction<_GetAcpNative, _GetAcpDart>('GetACP');
}

/// 当前系统 ANSI 代码页；非 Windows 返回 0。供测试判断是否跑 GBK 用例。
int serialNativeAcp() {
  if (!Platform.isWindows) return 0;
  _ensureKernel32();
  return _getAcp!();
}

String? _winAcpToString(List<int> bytes) {
  try {
    _ensureKernel32();
    final mbtowc = _multiByteToWideChar!;
    return using((arena) {
      final src = arena<Uint8>(bytes.length);
      src.asTypedList(bytes.length).setAll(0, bytes);
      final needed = mbtowc(_cpAcp, 0, src, bytes.length, nullptr, 0);
      if (needed <= 0) return null;
      final dest = arena<Uint16>(needed);
      final written = mbtowc(
        _cpAcp,
        0,
        src,
        bytes.length,
        dest.cast<Utf16>(),
        needed,
      );
      if (written <= 0) return null;
      return String.fromCharCodes(dest.asTypedList(written));
    });
  } catch (_) {
    return null;
  }
}
