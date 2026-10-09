import 'package:device_debug_tools/features/serial/data/serial_native_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('错误码 0 与成功文案不出现在失败详情中', () {
    expect(serialOsErrorDetail(code: 0, message: '操作成功完成'), '无法打开串口');
    expect(
      serialOsErrorDetail(
        code: 0,
        message: 'The operation completed successfully.',
      ),
      '无法打开串口',
    );
    expect(serialOsErrorDetail(message: '操作成功完成'), '无法打开串口');
  });

  test('真实错误文案保留', () {
    expect(
      serialOsErrorDetail(code: 31, message: '连到系统上的设备没有发挥作用'),
      '连到系统上的设备没有发挥作用',
    );
  });
}
