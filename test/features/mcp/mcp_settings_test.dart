import 'package:device_debug_tools/features/mcp/model/mcp_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('默认只开读取，策略为询问', () {
    const s = McpSettings.defaults;
    expect(s.enabled, isFalse);
    expect(s.allowRead, isTrue);
    expect(s.allowSend, isFalse);
    expect(s.allowReply, isFalse);
    expect(s.allowScript, isFalse);
    expect(s.allowQuick, isFalse);
    expect(s.replyPolicy, McpEnablePolicy.ask);
    expect(s.scriptPolicy, McpEnablePolicy.ask);
    expect(s.quickPolicy, McpEnablePolicy.ask);
    expect(s.port, McpLimits.defaultPort);
  });

  test('往返 JSON', () {
    final raw = McpSettings.defaults
        .copyWith(
          enabled: true,
          allowSend: true,
          allowQuick: true,
          quickPolicy: McpEnablePolicy.off,
          port: 40000,
        )
        .toJson();
    final parsed = McpSettings.fromJson(raw);
    expect(parsed.enabled, isTrue);
    expect(parsed.allowSend, isTrue);
    expect(parsed.allowQuick, isTrue);
    expect(parsed.quickPolicy, McpEnablePolicy.off);
    expect(parsed.port, 40000);
    expect(parsed.allowRead, isTrue);
  });
}
