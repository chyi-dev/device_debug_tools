import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_debug_tools/features/serial/data/lua_script_engine.dart';
import 'package:device_debug_tools/features/serial/data/serial_bytes.dart';
import 'package:device_debug_tools/features/serial/model/config_pack.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ConfigPack pack;

  setUp(() {
    final raw = jsonDecode(
      File('coffee-machine-jk89-config.json').readAsStringSync(),
    );
    pack = ConfigPack.fromJson(raw)!;
  });

  test('配置包可被导入解析', () {
    expect(pack.quick, isNotNull);
    expect(pack.rules, isNotNull);
    expect(pack.scripts, isNotNull);
    expect(pack.quick!.commands.length, greaterThan(20));
    expect(pack.enabledScripts, 3);
  });

  test('每条快捷指令校验和正确，且只命中一条应答', () {
    for (final command in pack.quick!.commands) {
      final bytes = SerialBytes.parseHex(command.data);
      expect(bytes, isNotNull, reason: command.name);
      final frame = bytes!;
      final sum = frame.sublist(0, frame.length - 1).fold<int>(0, (a, b) => a + b);
      expect(frame.last, sum & 0xFF, reason: '${command.name} 校验');
      final matched = [
        for (final rule in pack.rules!)
          if (SerialBytes.ruleMatches(rule, frame)) rule,
      ];
      expect(matched, hasLength(1), reason: command.name);
      final caps = SerialBytes.ruleCaptures(matched.single, frame);
      expect(caps, isNotNull, reason: command.name);
      final reply = SerialBytes.expandReply(
        matched.single.replies.single.data,
        caps!,
      );
      expect(reply, isNotNull, reason: command.name);
      final back = SerialBytes.parseHex(reply!)!;
      expect(back[0], 0xA5, reason: command.name);
      expect(back[3], frame[3], reason: '${command.name} 应答命令字');
      final backSum = back.sublist(0, back.length - 1).fold<int>(0, (a, b) => a + b);
      expect(back.last, backSum & 0xFF, reason: '${command.name} 应答校验');
    }
  });

  test('校验脚本保留已有 SUM8，并给缺校验的帧补上', () {
    final script = pack.scripts!.singleWhere((s) => s.name == 'jk89_checksum.lua');
    final engine = LuaScriptEngine();
    final info = engine.inspect(script.id, script.code);
    expect(info.error, isNull);
    expect(info.hooks, {ScriptHook.beforeSend});

    final ready = SerialBytes.parseHex('AA 55 02 1E 1F')!;
    final kept = engine.beforeSend(script.id, script.code, ready);
    expect(kept.error, isNull);
    expect(kept.bytes, ready);

    final bare = Uint8List.fromList([0xAA, 0x55, 0x02, 0x1E]);
    final filled = engine.beforeSend(script.id, script.code, bare);
    expect(filled.bytes, ready);
  });

  test('状态与制作脚本能解析模拟应答', () {
    final engine = LuaScriptEngine();
    final status = pack.scripts!.singleWhere(
      (s) => s.name == 'jk89_parse_status.lua',
    );
    final making = pack.scripts!.singleWhere(
      (s) => s.name == 'jk89_parse_making.lua',
    );
    expect(engine.inspect(status.id, status.code).error, isNull);
    expect(engine.inspect(making.id, making.code).error, isNull);

    final statusReply = SerialBytes.parseHex(
      pack.rules!.singleWhere((r) => r.id == 'r-1e').replies.single.data,
    )!;
    final statusOut = engine.receive(status.id, status.code, statusReply);
    expect(statusOut.error, isNull);
    expect(statusOut.logs, ['0x1E 整机 正常空闲', '0x1E 故障 无']);

    final makingReply = SerialBytes.parseHex(
      pack.rules!.singleWhere((r) => r.id == 'r-1f').replies.single.data,
    )!;
    final makingOut = engine.receive(making.id, making.code, makingReply);
    expect(makingOut.error, isNull);
    expect(makingOut.logs.single, contains('成功'));
    expect(makingOut.logs.single, contains('热'));
  });
}
