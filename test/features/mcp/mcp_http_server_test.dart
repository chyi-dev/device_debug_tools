import 'dart:convert';
import 'dart:io';

import 'package:device_debug_tools/features/mcp/data/mcp_http_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initialize 与 tools/list', () async {
    var seen = false;
    final server = McpHttpServer(
      onClientSeen: () => seen = true,
      onRpc: (method, params) async {
        if (method == 'initialize') {
          return {
            'protocolVersion': '2024-11-05',
            'capabilities': {'tools': <String, Object>{}},
            'serverInfo': {'name': 't', 'version': '1'},
          };
        }
        if (method == 'tools/list') {
          return {
            'tools': [
              {'name': 'list_connections'},
            ],
          };
        }
        throw McpRpcException('nope');
      },
    );
    final port = await server.start(preferredPort: 39290);
    addTearDown(server.stop);

    final client = HttpClient();
    Future<Map<String, dynamic>> post(Object body) async {
      final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port/mcp'),
      );
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));
      final res = await req.close();
      final text = await utf8.decoder.bind(res).join();
      return jsonDecode(text) as Map<String, dynamic>;
    }

    final init = await post({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {},
    });
    expect(seen, isTrue);
    expect(init['result'], isA<Map>());

    final list = await post({
      'jsonrpc': '2.0',
      'id': 2,
      'method': 'tools/list',
      'params': {},
    });
    final tools = (list['result'] as Map)['tools'] as List;
    expect(tools, isNotEmpty);
    client.close(force: true);
  });
}
