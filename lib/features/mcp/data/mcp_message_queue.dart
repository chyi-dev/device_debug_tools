import 'dart:async';

import '../model/mcp_models.dart';

/// 询问消息队列：满则丢掉最早未处理项，处理完才移除。
class McpMessageQueue {
  McpMessageQueue({this.maxSize = McpLimits.messageQueue});

  final int maxSize;
  final List<_Queued> _items = [];

  int get length => _items.length;

  List<McpPendingMessage> get pending =>
      [for (final item in _items) item.message];

  /// 入队。若已满，先丢掉最早的启用确认（条目通常已导入未启用），返回被丢掉的项。
  McpPendingMessage? enqueue(
    McpPendingMessage message,
    Completer<McpAskOutcome> completer,
  ) {
    McpPendingMessage? dropped;
    if (_items.length >= maxSize) {
      final first = _items.removeAt(0);
      if (!first.completer.isCompleted) {
        first.completer.complete(McpAskOutcome.dropped);
      }
      dropped = first.message;
    }
    _items.add(_Queued(message: message, completer: completer));
    return dropped;
  }

  McpPendingMessage? byId(String id) {
    for (final item in _items) {
      if (item.message.id == id) return item.message;
    }
    return null;
  }

  /// 完成并移除；找不到返回 false。
  bool complete(String id, McpAskOutcome outcome) {
    final index = _items.indexWhere((item) => item.message.id == id);
    if (index < 0) return false;
    final item = _items.removeAt(index);
    if (!item.completer.isCompleted) {
      item.completer.complete(outcome);
    }
    return true;
  }

  /// 作废尚未处理的启用确认（关 MCP / 关授权）；条目通常已导入未启用。
  List<McpPendingMessage> revokeWhere(bool Function(McpPendingMessage) test) {
    final revoked = <McpPendingMessage>[];
    final keep = <_Queued>[];
    for (final item in _items) {
      if (test(item.message)) {
        if (!item.completer.isCompleted) {
          item.completer.complete(McpAskOutcome.revoked);
        }
        revoked.add(item.message);
      } else {
        keep.add(item);
      }
    }
    _items
      ..clear()
      ..addAll(keep);
    return revoked;
  }

  void clearAll({required McpAskOutcome outcome}) {
    for (final item in _items) {
      if (!item.completer.isCompleted) {
        item.completer.complete(outcome);
      }
    }
    _items.clear();
  }
}

class _Queued {
  _Queued({required this.message, required this.completer});

  final McpPendingMessage message;
  final Completer<McpAskOutcome> completer;
}
