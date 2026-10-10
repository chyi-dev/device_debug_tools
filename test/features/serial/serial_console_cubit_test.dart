import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:device_debug_tools/core/exception/app_exception.dart';
import 'package:device_debug_tools/features/serial/cubit/serial_console_cubit.dart';
import 'package:device_debug_tools/features/serial/data/serial_bytes.dart';
import 'package:device_debug_tools/features/serial/data/serial_file_gateway.dart';
import 'package:device_debug_tools/features/serial/data/serial_port_gateway.dart';
import 'package:device_debug_tools/features/serial/data/serial_workspace_store.dart';
import 'package:device_debug_tools/features/serial/model/script_lessons.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:device_debug_tools/features/serial/repository/serial_console_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakePorts ports;
  late _FakeFiles files;
  late SerialConsoleCubit cubit;

  setUp(() async {
    ports = _FakePorts();
    files = _FakeFiles();
    cubit = SerialConsoleCubit(
      repository: SerialConsoleRepository(
        ports: ports,
        files: files,
        store: _MemoryStore(),
      ),
    );
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
  });

  test('串口关闭时发送被拦截且不记历史', () async {
    await cubit.sendFromEditor();
    expect(cubit.state.toast?.kind, SerialNoticeKind.portClosedSend);
    expect(cubit.state.lines.where((line) => line.dir == LogDir.tx), isEmpty);
    expect(cubit.state.history, isEmpty);
  });

  test('发送按钮记入历史，快捷指令不记入', () async {
    cubit.setTxText('A5 01 00 00 01 07');
    cubit.upsertQuick(
      const QuickCommand(
        id: 'q1',
        name: '读取温湿度',
        data: 'A5 01 00 00 01 07',
        format: DataFormat.hex,
        key: 'F1',
      ),
    );
    await cubit.toggleOpen();
    await cubit.sendFromEditor();
    expect(cubit.state.history.single.text, 'A5 01 00 00 01 07');
    expect(cubit.state.txCount, 6);
    final before = cubit.state.history.length;
    await cubit.sendQuick('q1');
    expect(cubit.state.history.length, before);
    expect(ports.written, hasLength(2));
  });

  test('收到匹配帧后按延时自动应答', () async {
    cubit.upsertRule(
      const ReplyRule(
        id: 'r1',
        name: '温湿度回包确认',
        match: MatchMode.prefix,
        pattern: 'A5 5A 03',
        enabled: true,
        hits: 0,
        replies: [
          ReplyStep(data: 'A5 A0 00 A0', delayMs: 80),
          ReplyStep(data: 'A5 A1 01 A2', delayMs: 120),
        ],
      ),
    );
    await cubit.toggleOpen();
    ports.emit(Uint8List.fromList([0xA5, 0x5A, 0x03, 0x11]));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(cubit.state.rules.firstWhere((rule) => rule.id == 'r1').hits, 1);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(ports.written.map(SerialBytes.toHex), contains('A5 A0 00 A0'));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(ports.written.map(SerialBytes.toHex), contains('A5 A1 01 A2'));
  });

  test(r'应答里的 $1 换成帧中捕获的字节再发出', () async {
    cubit.upsertRule(
      const ReplyRule(
        id: 'r2',
        name: '序号回显',
        match: MatchMode.prefix,
        pattern: 'A5 10 ??',
        enabled: true,
        hits: 0,
        replies: [ReplyStep(data: r'A5 90 $1', delayMs: 10)],
      ),
    );
    await cubit.toggleOpen();
    ports.emit(Uint8List.fromList([0xA5, 0x10, 0x3C, 0x00]));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(ports.written.map(SerialBytes.toHex), contains('A5 90 3C'));
  });

  group('快捷指令文件夹', () {
    const read = QuickCommand(
      id: 'q1',
      name: '读取温湿度',
      data: 'A5 01 00 00 01 07',
      format: DataFormat.hex,
      key: 'F1',
    );
    const stop = QuickCommand(
      id: 'q2',
      name: '停止采集',
      data: 'A5 10 00 00 10',
      format: DataFormat.hex,
    );

    String addFolder(String name) {
      cubit.upsertFolder(null, name);
      return cubit.state.quick.folders.last.id;
    }

    test('旧的平铺数据读入后留在根目录，重复 F 键保留先出现的', () {
      final ws = SerialWorkspace.fromJson({
        'quick': [
          {'id': 'q1', 'name': 'A', 'data': '01', 'format': 'hex', 'key': 'F1'},
          {'id': 'q2', 'name': 'B', 'data': '02', 'format': 'hex', 'key': 'F1'},
        ],
      })!;
      expect(ws.quick, everyElement(isA<QuickCommand>()));
      expect(ws.quick.commands.map((c) => c.key), ['F1', '']);
    });

    test('文件夹随工作区 JSON 往返', () {
      cubit.upsertQuick(read);
      final f = addFolder('采集');
      cubit.upsertQuick(stop, folderId: f);
      cubit.toggleFolder(f);
      final json = jsonDecode(jsonEncode(cubit.state.toWorkspace().toJson()));
      final back = SerialWorkspace.fromJson(json)!;
      final folder = back.quick[1] as QuickFolder;
      expect(back.quick.first, isA<QuickCommand>());
      expect(folder.name, '采集');
      expect(folder.expanded, isFalse);
      expect(folder.commands.single.id, 'q2');
    });

    test('写入文件夹、跨文件夹移动并追加到末尾、快捷键全局互斥', () {
      final a = addFolder('A');
      final b = addFolder('B');
      cubit.upsertQuick(read, folderId: a);
      cubit.upsertQuick(stop, folderId: b);
      expect(cubit.state.quick.folderIdOf('q1'), a);

      cubit.upsertQuick(read, folderId: b);
      final folderB = cubit.state.quick.folders.firstWhere((f) => f.id == b);
      expect(folderB.commands.map((c) => c.id), ['q2', 'q1']);
      expect(cubit.state.quick.folders.first.commands, isEmpty);

      cubit.upsertQuick(
        const QuickCommand(
          id: 'q3',
          name: '新',
          data: '01',
          format: DataFormat.hex,
          key: 'F1',
        ),
      );
      expect(cubit.state.quick.last.id, 'q3');
      expect(cubit.state.quick.commandById('q1')!.key, '');
    });

    test('原文件夹内编辑保持位置', () {
      final a = addFolder('A');
      cubit.upsertQuick(read, folderId: a);
      cubit.upsertQuick(stop, folderId: a);
      cubit.upsertQuick(read.copyWith(key: 'F2'), folderId: a);
      final folder = cubit.state.quick.folders.single;
      expect(folder.commands.map((c) => c.id), ['q1', 'q2']);
      expect(folder.commands.first.key, 'F2');
    });

    test('删除文件夹连带其中指令', () {
      final a = addFolder('A');
      cubit.upsertQuick(read, folderId: a);
      cubit.upsertQuick(stop);
      cubit.deleteFolder(a);
      expect(cubit.state.quick.folders, isEmpty);
      expect(cubit.state.quick.commands.map((c) => c.id), ['q2']);
    });

    test('文件夹内指令可由 F 键发送且不进历史', () async {
      final a = addFolder('A');
      cubit.upsertQuick(read, folderId: a);
      cubit.toggleFolder(a);
      expect(cubit.state.quick.folders.single.expanded, isFalse);
      await cubit.toggleOpen();
      await cubit.sendQuickByKey('F1');
      expect(ports.written.map(SerialBytes.toHex), ['A5 01 00 00 01 07']);
      expect(cubit.state.history, isEmpty);
    });

    test('导入新树按指令条数提示，旧数组也能导入', () async {
      files.text = jsonEncode([
        {
          'type': 'command',
          'id': 'q1',
          'name': 'A',
          'data': '01',
          'format': 'hex',
        },
        {
          'type': 'folder',
          'id': 'f1',
          'name': '组',
          'commands': [
            {'id': 'q2', 'name': 'B', 'data': '02', 'format': 'hex'},
            {'id': 'q3', 'name': 'C', 'data': '03', 'format': 'hex'},
          ],
        },
      ]);
      await cubit.importQuick();
      expect(cubit.state.quick.folders.single.commands, hasLength(2));
      expect(cubit.state.toast?.kind, SerialNoticeKind.imported);
      expect(cubit.state.toast?.args['count'], 3);

      files.text = jsonEncode([
        {'name': 'X', 'data': '01', 'format': 'HEX', 'key': 'F3'},
      ]);
      await cubit.importQuick();
      expect(cubit.state.quick.single, isA<QuickCommand>());
      expect(cubit.state.quick.commands.single.key, 'F3');
    });
  });

  group('Lua 脚本', () {
    String idOf(String name) =>
        cubit.state.scripts.firstWhere((s) => s.name == name).id;

    test('预置脚本：on_receive 解析温湿度写入运行日志', () async {
      expect(cubit.state.scripts.map((s) => s.name), [
        'parse_sensor.lua',
        'add_checksum.lua',
      ]);
      final meta = cubit.state.scriptMeta[idOf('parse_sensor.lua')]!;
      expect(meta.hooks, {ScriptHook.onReceive});
      await cubit.toggleOpen();
      ports.emit(
        Uint8List.fromList([0xA5, 0x5A, 0x03, 0x00, 0xF6, 0x02, 0x09]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final log = cubit.state.scriptLog.single;
      expect(log.kind, ScriptLogKind.output);
      expect(log.text, 'temp=24.6℃ hum=52.1%');
      expect(cubit.state.scriptMeta[idOf('parse_sensor.lua')]!.outputs, 1);
    });

    test('before_send 改写所有发送路径的帧', () async {
      cubit.toggleScript(idOf('add_checksum.lua'));
      await cubit.toggleOpen();
      cubit.setTxText('A5 01 00 00 01');
      await cubit.sendFromEditor();
      expect(SerialBytes.toHex(ports.written.single), 'A5 01 00 00 01 A7');
      final tx = cubit.state.lines.lastWhere((l) => l.dir == LogDir.tx);
      expect(SerialBytes.toHex(tx.bytes!), 'A5 01 00 00 01 A7');
      expect(cubit.state.history.first.text, 'A5 01 00 00 01');
      expect(cubit.state.scriptLog.last.kind, ScriptLogKind.changed);
    });

    test('before_send 返回 nil 拦截，出错也拦截', () async {
      cubit.newScript();
      final id = cubit.state.selectedScriptId!;
      cubit.setScriptCode(
        id,
        'function before_send(f)\n'
        '  if f:u8(1) == 0xFF then return nil end\n'
        '  if f:u8(1) == 0xEE then error("bad") end\n'
        '  return f\n'
        'end',
      );
      cubit.toggleScript(id);
      await cubit.toggleOpen();
      cubit.setTxText('FF 01');
      await cubit.sendFromEditor();
      cubit.setTxText('EE 01');
      await cubit.sendFromEditor();
      cubit.setTxText('01 02');
      await cubit.sendFromEditor();
      expect(ports.written.map(SerialBytes.toHex), ['01 02']);
      final sys = cubit.state.lines
          .where((l) => l.dir == LogDir.sys)
          .map((l) => l.sys)
          .toList();
      expect(sys, contains(SysLogKind.scriptBlocked));
      expect(sys, contains(SysLogKind.scriptFailed));
      expect(
        cubit.state.scriptLog.where((e) => e.kind == ScriptLogKind.error),
        hasLength(1),
      );
    });

    test('手动运行 before_send 只试算不发送', () async {
      await cubit.toggleOpen();
      cubit.setTxText('A5 01 00 00 01');
      cubit.runScript(idOf('add_checksum.lua'));
      expect(ports.written, isEmpty);
      final log = cubit.state.scriptLog.last;
      expect(log.kind, ScriptLogKind.dryRun);
      expect(log.to, 'A5 01 00 00 01 A7');
    });

    test('脚本随工作区 JSON 往返，旧数据补预置脚本', () {
      final ws = cubit.state.toWorkspace();
      final back = SerialWorkspace.fromJson(
        jsonDecode(jsonEncode(ws.toJson())),
      )!;
      expect(back.scripts.map((s) => s.code), ws.scripts.map((s) => s.code));
      expect(back.scripts.first.enabled, isTrue);
      final legacy = SerialWorkspace.fromJson({'baud': 9600})!;
      expect(legacy.scripts, hasLength(2));
    });
  });

  group('Lua 教程', () {
    List<ScriptLogEntry> tryLesson(String key) {
      final before = cubit.state.scriptLog.length;
      cubit.tryLesson(ScriptLesson.byKey(key)!);
      return cubit.state.scriptLog.sublist(before);
    }

    test('每课样例试跑输出与说明一致，不发送也不计入脚本', () async {
      await cubit.toggleOpen();
      final meta = cubit.state.scriptMeta;
      final outputs = {
        for (final lesson in ScriptLesson.all)
          lesson.key: [
            for (final e in tryLesson(lesson.key))
              if (e.kind == ScriptLogKind.output) e.text,
          ],
      };
      expect(outputs, {
        'hooks': ['收到 5 字节'],
        'print': ['A5 5A 03 00 F6 02 09 03', '帧头 A5 5A', '末字节 3'],
        'parse': ['温度 24.6℃ 湿度 52.1%'],
        'checksum': <String>[],
        'block': ['已拦截停止采集'],
        'modbus': <String>[],
      });
      expect(cubit.state.scriptLog.where((e) => e.isError), isEmpty);
      expect(ports.written, isEmpty);
      expect(cubit.state.scriptMeta, meta);
      expect(cubit.state.hint.kind, SerialNoticeKind.lessonTried);
    });

    test('before_send 课的试算结果', () {
      final checksum = tryLesson('checksum');
      expect(checksum.first.kind, ScriptLogKind.lessonTry);
      expect(checksum.first.text, 'before_send');
      expect(checksum.first.from, 'A5 01 00 00 01');
      expect(checksum.last.kind, ScriptLogKind.dryRun);
      expect(checksum.last.to, 'A5 01 00 00 01 A7');
      expect(tryLesson('block').last.kind, ScriptLogKind.dryBlocked);
      expect(tryLesson('modbus').last.to, '01 03 00 00 00 01 84 0A');
    });

    test('用课新建脚本：停用、选中、切回列表，重名加序号', () {
      final lesson = ScriptLesson.byKey('parse')!;
      cubit.setScriptTutorial(true);
      cubit.newScriptFromLesson(lesson);
      final first = cubit.state.selectedScript!;
      expect(first.name, 'lesson3_parse.lua');
      expect(first.code, lesson.code);
      expect(first.enabled, isFalse);
      expect(cubit.state.scriptTutorial, isFalse);
      expect(cubit.state.scriptDock, isTrue);
      expect(cubit.state.scriptMeta[first.id]!.hooks, {ScriptHook.onReceive});
      expect(cubit.state.hint.kind, SerialNoticeKind.lessonCreated);

      cubit.newScriptFromLesson(lesson);
      expect(cubit.state.selectedScript!.name, 'lesson3_parse_2.lua');
    });

    test('课表展开与收起', () {
      expect(cubit.state.openLesson, 'hooks');
      cubit.toggleLesson('parse');
      expect(cubit.state.openLesson, 'parse');
      cubit.toggleLesson('parse');
      expect(cubit.state.openLesson, isNull);
    });
  });

  test('降级打开成功时端口为打开并提示部分参数', () async {
    ports.openResult = SerialOpenResult.partial;
    await cubit.toggleOpen();
    expect(cubit.state.open, isTrue);
    expect(cubit.state.toast?.kind, SerialNoticeKind.configPartial);
  });

  test('参数全失败时走 configFailed 且端口仍关闭', () async {
    ports.openError = DeviceConfigException('SetCommState failed');
    await cubit.toggleOpen();
    expect(cubit.state.open, isFalse);
    expect(cubit.state.toast?.kind, SerialNoticeKind.configFailed);
  });
}

class _FakePorts implements SerialPortGateway {
  final _incoming = StreamController<Uint8List>.broadcast();
  final written = <Uint8List>[];
  var opened = false;
  SerialOpenResult openResult = SerialOpenResult.full;
  Object? openError;

  void emit(Uint8List bytes) => _incoming.add(bytes);

  @override
  Future<void> apply(SerialLinkConfig config) async {}

  @override
  Future<void> close() async {
    opened = false;
  }

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  bool get isOpen => opened;

  @override
  Future<List<SerialPortInfo>> listPorts() async => const [
    SerialPortInfo(name: 'COM3', label: 'COM3 · test'),
  ];

  @override
  Future<SerialOpenResult> open(SerialLinkConfig config) async {
    final error = openError;
    if (error != null) throw error;
    opened = true;
    return openResult;
  }

  @override
  PinLevels readPins() => const PinLevels(dcd: true);

  @override
  Future<void> write(Uint8List data) async {
    written.add(Uint8List.fromList(data));
  }
}

class _FakeFiles implements SerialFileGateway {
  String? text;

  @override
  Future<PickedBytes?> pickAny() async => null;

  @override
  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) async => null;

  @override
  Future<String?> pickText({required List<String> extensions}) async => text;

  @override
  Future<void> writeText({required String path, required String text}) async {}
}

class _MemoryStore implements SerialWorkspaceStore {
  SerialWorkspace? saved;

  @override
  SerialWorkspace? read() => saved;

  @override
  Future<void> write(SerialWorkspace workspace) async {
    saved = workspace;
  }
}
