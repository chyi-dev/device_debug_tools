import 'dart:typed_data';

import 'package:device_debug_tools/features/serial/data/lua_script_engine.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _b(List<int> v) => Uint8List.fromList(v);

void main() {
  late LuaScriptEngine engine;

  setUp(() => engine = LuaScriptEngine(instructionBudget: 200000));

  test('识别钩子并在 on_receive 中解析帧', () {
    const code = '''
function on_receive(frame)
  if frame:starts_with(0xA5, 0x5A, 0x03) then
    local t = frame:u16(4) / 10
    local h = frame:u16(6) / 10
    log(string.format("temp=%.1f hum=%.1f%%", t, h))
  end
end''';
    final info = engine.inspect('a', code);
    expect(info.error, isNull);
    expect(info.hooks, {ScriptHook.onReceive});
    final out = engine.receive(
      'a',
      code,
      _b([0xA5, 0x5A, 0x03, 0x01, 0x02, 0x02, 0x3A]),
    );
    expect(out.error, isNull);
    expect(out.logs, ['temp=25.8 hum=57.0%']);
  });

  test('before_send 追加校验与拦截', () {
    const code = '''
function before_send(frame)
  if frame:u8(1) == 0xFF then return nil end
  return frame:append(sum8(frame))
end''';
    final ok = engine.beforeSend('b', code, _b([0xA5, 0x01, 0x00, 0x00, 0x01]));
    expect(ok.error, isNull);
    expect(ok.bytes, [0xA5, 0x01, 0x00, 0x00, 0x01, 0xA7]);
    final blocked = engine.beforeSend('b', code, _b([0xFF]));
    expect(blocked.bytes, isNull);
    expect(blocked.error, isNull);
  });

  test('工具函数与 log', () {
    const code = '''
function on_receive(f)
  log(f, f:len(), xor8(f), f:sub(2):hex(), f:u16le(1))
  local lo, hi = crc16(frame(0x01, 0x03, 0x00, 0x00, 0x00, 0x01))
  log(string.format('%02X %02X', lo, hi))
  log(frame('AB'):hex(), f:append({1, 2}, 3):len())
end''';
    final out = engine.receive('c', code, _b([0x01, 0x02, 0x03]));
    expect(out.error, isNull);
    expect(out.logs, ['01 02 03 3 0 02 03 513', '84 0A', '41 42 6']);
  });

  test('十六进制字面量改写跳过字符串与注释', () {
    expect(
      rewriteHexLiterals("x = 0xFF -- 0x10\ns = '0x20' .. [[0x30]] y=a0x1"),
      "x = 255 -- 0x10\ns = '0x20' .. [[0x30]] y=a0x1",
    );
    expect(rewriteHexLiterals('a-0xFFFFFFFFFFFFFFFF'), 'a-(-1)');
  });

  test('语法错误、运行错误与死循环', () {
    expect(engine.inspect('d', 'function on_receive(').error, isNotNull);
    final runtime = engine.receive(
      'e',
      'function on_receive(f) error("boom") end',
      _b([1]),
    );
    expect(runtime.error, contains('boom'));
    final loop = engine.beforeSend(
      'f',
      'function before_send(f) while true do end end',
      _b([1]),
    );
    expect(loop.bytes, isNull);
    expect(loop.tooLong, isTrue);
    expect(engine.inspect('g', 'os.exit()').error, isNotNull);
  });
}
