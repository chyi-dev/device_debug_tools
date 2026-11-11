import 'dart:async';

import 'package:device_debug_tools/features/mcp/data/mcp_message_queue.dart';
import 'package:device_debug_tools/features/mcp/model/mcp_models.dart';
import 'package:flutter_test/flutter_test.dart';

McpPendingMessage _msg(String id, {String name = 'a.lua'}) {
  return McpPendingMessage(
    id: id,
    kind: McpMessageKind.script,
    tabId: 't1',
    tabName: '传感器',
    name: name,
    body: 'code',
    enqueuedAt: DateTime.now(),
  );
}

void main() {
  test('入队顺序与处理完才移除', () async {
    final queue = McpMessageQueue(maxSize: 3);
    final c1 = Completer<McpAskOutcome>();
    final c2 = Completer<McpAskOutcome>();
    expect(queue.enqueue(_msg('1'), c1), isNull);
    expect(queue.enqueue(_msg('2'), c2), isNull);
    expect(queue.length, 2);
    expect(queue.complete('1', McpAskOutcome.enabled), isTrue);
    expect(await c1.future, McpAskOutcome.enabled);
    expect(queue.length, 1);
    expect(queue.pending.single.id, '2');
  });

  test('第 101 条挤掉最早的启用确认', () async {
    final queue = McpMessageQueue(maxSize: 100);
    final first = Completer<McpAskOutcome>();
    queue.enqueue(_msg('first', name: 'first.lua'), first);
    for (var i = 0; i < 99; i++) {
      queue.enqueue(_msg('m$i'), Completer<McpAskOutcome>());
    }
    expect(queue.length, 100);
    final dropped = queue.enqueue(
      _msg('new', name: 'new.lua'),
      Completer<McpAskOutcome>(),
    );
    expect(dropped?.id, 'first');
    expect(await first.future, McpAskOutcome.dropped);
    expect(queue.length, 100);
    expect(queue.pending.first.id, isNot('first'));
    expect(queue.pending.last.name, 'new.lua');
  });

  test('关掉授权时未决项作废', () async {
    final queue = McpMessageQueue();
    final c = Completer<McpAskOutcome>();
    queue.enqueue(_msg('1'), c);
    final revoked = queue.revokeWhere((m) => m.kind == McpMessageKind.script);
    expect(revoked, hasLength(1));
    expect(await c.future, McpAskOutcome.revoked);
    expect(queue.length, 0);
  });
}
