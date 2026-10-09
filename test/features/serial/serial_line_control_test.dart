import 'package:device_debug_tools/features/serial/data/serial_line_control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows 上关闭线路时跳过写入', () {
    expect(
      serialLineControlValue(on: false, isWindows: true),
      isNull,
    );
  });

  test('Windows 上开启线路时写入 ON', () {
    expect(
      serialLineControlValue(on: true, isWindows: true),
      isTrue,
    );
  });

  test('非 Windows 上关闭线路时写入 OFF', () {
    expect(
      serialLineControlValue(on: false, isWindows: false),
      isFalse,
    );
  });

  test('非 Windows 上开启线路时写入 ON', () {
    expect(
      serialLineControlValue(on: true, isWindows: false),
      isTrue,
    );
  });
}
