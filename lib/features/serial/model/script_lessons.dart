import 'serial_models.dart';

/// 脚本页「教程」的一课：标题与说明走 slang（`serial.script.lessons.<key>`），
/// 代码与样例帧不翻译；代码只能用 `lua_script_engine.dart` prelude 里已有的接口。
class ScriptLesson {
  const ScriptLesson({
    required this.key,
    required this.fileName,
    required this.hook,
    required this.code,
    required this.sample,
  });

  final String key;

  /// 用这课新建脚本时的默认文件名。
  final String fileName;
  final ScriptHook hook;
  final String code;

  /// 样例试跑用的帧（HEX）。
  final String sample;

  /// Lua 里的钩子函数名，属于脚本接口，不翻译。
  String get hookName => switch (hook) {
    ScriptHook.onReceive => 'on_receive',
    ScriptHook.beforeSend => 'before_send',
  };

  static const all = [
    ScriptLesson(
      key: 'hooks',
      fileName: 'lesson1_hooks.lua',
      hook: ScriptHook.onReceive,
      sample: 'A5 81 00 00 81',
      code:
          '-- 收到一包数据后运行，frame 是这一包的字节\n'
          'function on_receive(frame)\n'
          '  log("收到", frame:len(), "字节")\n'
          'end\n',
    ),
    ScriptLesson(
      key: 'print',
      fileName: 'lesson2_print.lua',
      hook: ScriptHook.onReceive,
      sample: 'A5 5A 03 00 F6 02 09 03',
      code:
          'function on_receive(frame)\n'
          '  log(frame)                     -- 整帧 HEX\n'
          '  log("帧头", frame:sub(1, 2))   -- 第 1~2 字节\n'
          '  log("末字节", frame:u8(frame:len()))\n'
          'end\n',
    ),
    ScriptLesson(
      key: 'parse',
      fileName: 'lesson3_parse.lua',
      hook: ScriptHook.onReceive,
      sample: 'A5 5A 03 00 F6 02 09 03',
      code:
          '-- 温湿度帧：A5 5A 03 温度(2) 湿度(2) 校验\n'
          'function on_receive(frame)\n'
          '  if not frame:starts_with(0xA5, 0x5A, 0x03) then return end\n'
          '  local t = frame:u16(4) / 10\n'
          '  local h = frame:u16(6) / 10\n'
          '  log(string.format("温度 %.1f℃ 湿度 %.1f%%", t, h))\n'
          'end\n',
    ),
    ScriptLesson(
      key: 'checksum',
      fileName: 'lesson4_checksum.lua',
      hook: ScriptHook.beforeSend,
      sample: 'A5 01 00 00 01',
      code:
          '-- 发出前在帧尾补 SUM8\n'
          'function before_send(frame)\n'
          '  return frame:append(sum8(frame))\n'
          '  -- 改用异或校验：return frame:append(xor8(frame))\n'
          'end\n',
    ),
    ScriptLesson(
      key: 'block',
      fileName: 'lesson5_block.lua',
      hook: ScriptHook.beforeSend,
      sample: 'A5 10 00 00 10',
      code:
          '-- 不让「停止采集」发出去，其余照常\n'
          'function before_send(frame)\n'
          '  if frame:starts_with(0xA5, 0x10, 0x00) then\n'
          '    log("已拦截停止采集")\n'
          '    return nil\n'
          '  end\n'
          '  return frame\n'
          'end\n',
    ),
    ScriptLesson(
      key: 'modbus',
      fileName: 'lesson6_modbus.lua',
      hook: ScriptHook.beforeSend,
      sample: '01 03 00 00 00 01',
      code:
          '-- Modbus RTU：帧尾追加 CRC16，低字节在前\n'
          'function before_send(frame)\n'
          '  local lo, hi = crc16(frame)\n'
          '  return frame:append(lo, hi)\n'
          'end\n',
    ),
  ];

  static ScriptLesson? byKey(String key) {
    for (final lesson in all) {
      if (lesson.key == key) return lesson;
    }
    return null;
  }
}
