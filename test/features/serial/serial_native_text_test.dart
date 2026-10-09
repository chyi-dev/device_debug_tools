import 'dart:convert';
import 'dart:io';

import 'package:device_debug_tools/features/serial/data/serial_native_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ASCII 错误详情保持不变', () {
    expect(decodeSerialNativeText('Access is denied.'), 'Access is denied.');
    expect(decodeSerialNativeText(''), '');
  });

  test('中文 Windows 将 Latin-1 误读的 GBK 还原为「端口」', () {
    if (!Platform.isWindows || serialNativeAcp() != 936) {
      return;
    }
    // GBK 字节 B6 CB BF DA = 「端口」，经 latin1 得到乱码后再还原。
    final mojibake = latin1.decode([0xB6, 0xCB, 0xBF, 0xDA]);
    expect(decodeSerialNativeText(mojibake), '端口');
  });
}
