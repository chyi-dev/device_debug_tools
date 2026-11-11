import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';

typedef McpRpcHandler = FutureOr<Object?> Function(
  String method,
  Object? params,
);

/// 仅绑定 127.0.0.1 的 MCP JSON-RPC（POST /mcp）。
class McpHttpServer {
  McpHttpServer({required this.onRpc, required this.onClientSeen});

  final McpRpcHandler onRpc;
  final void Function() onClientSeen;

  HttpServer? _server;
  int? _boundPort;

  int? get boundPort => _boundPort;

  bool get isRunning => _server != null;

  Future<int> start({required int preferredPort}) async {
    await stop();
    Object? lastError;
    for (var i = 0; i < 20; i++) {
      final port = preferredPort + i;
      try {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
        _server = server;
        _boundPort = port;
        server.listen(_onRequest, onError: (Object e, StackTrace s) {
          AppLogger.i.error(
            'MCP HTTP listen error',
            category: LogCategory.app,
            error: e,
            stackTrace: s,
          );
        });
        AppLogger.i.info('MCP listening on 127.0.0.1:$port');
        return port;
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('MCP bind failed near $preferredPort: $lastError');
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _boundPort = null;
    if (server != null) {
      await server.close(force: true);
    }
  }

  Future<void> _onRequest(HttpRequest request) async {
    try {
      if (request.method == 'OPTIONS') {
        _cors(request.response);
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return;
      }
      if (request.uri.path != '/mcp' && request.uri.path != '/') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      if (request.method != 'POST') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
      }
      final raw = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final out = <Object?>[];
        for (final item in decoded) {
          out.add(await _handleOne(item));
        }
        await _writeJson(request.response, out);
        return;
      }
      final result = await _handleOne(decoded);
      if (result == null) {
        request.response.statusCode = HttpStatus.accepted;
        await request.response.close();
        return;
      }
      await _writeJson(request.response, result);
    } catch (e, s) {
      AppLogger.i.error(
        'MCP request failed',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<Object?> _handleOne(Object? raw) async {
    if (raw is! Map) {
      return _error(null, -32600, 'Invalid Request');
    }
    final id = raw['id'];
    final method = raw['method']?.toString();
    if (method == null || method.isEmpty) {
      return _error(id, -32600, 'Invalid Request');
    }
    // 通知无 id，不回包。
    if (id == null && method.startsWith('notifications/')) {
      if (method == 'notifications/initialized') {
        onClientSeen();
      }
      return null;
    }
    try {
      if (method == 'initialize') {
        onClientSeen();
      }
      final result = await onRpc(method, raw['params']);
      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': result,
      };
    } on McpRpcException catch (e) {
      return _error(id, e.code, e.message, data: e.data);
    } catch (e) {
      return _error(id, -32603, e.toString());
    }
  }

  Map<String, Object?> _error(
    Object? id,
    int code,
    String message, {
    Object? data,
  }) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      },
    };
  }

  void _cors(HttpResponse response) {
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'content-type');
  }

  Future<void> _writeJson(HttpResponse response, Object body) async {
    _cors(response);
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }
}

class McpRpcException implements Exception {
  McpRpcException(this.message, {this.code = -32000, this.data});

  final int code;
  final String message;
  final Object? data;

  @override
  String toString() => message;
}
