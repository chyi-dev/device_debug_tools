import 'package:device_debug_tools/features/mcp/model/mcp_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _tabs = [
  McpConnectionInfo(id: 'a1', name: '传感器', kind: 'serial', open: true),
  McpConnectionInfo(id: 'b2', name: '模组', kind: 'ble', open: true),
  McpConnectionInfo(id: 'c3', name: '传感器', kind: 'mqtt', open: false),
];

void main() {
  test('仅 tabId', () {
    final result = resolveMcpTab(tabs: _tabs, tabId: 'b2');
    expect(result, isA<McpBridgeOk>());
    final tab = (result as McpBridgeOk).data as McpResolvedTab;
    expect(tab.id, 'b2');
    expect(tab.name, '模组');
  });

  test('仅 tabName 且唯一', () {
    final result = resolveMcpTab(tabs: _tabs, tabName: '模组');
    expect(result, isA<McpBridgeOk>());
    final tab = (result as McpBridgeOk).data as McpResolvedTab;
    expect(tab.id, 'b2');
  });

  test('同名冲突', () {
    final result = resolveMcpTab(tabs: _tabs, tabName: '传感器');
    expect(result, isA<McpBridgeErr>());
    expect((result as McpBridgeErr).code, 'tab_name_ambiguous');
  });

  test('两者都传且一致', () {
    final result = resolveMcpTab(
      tabs: _tabs,
      tabId: 'a1',
      tabName: '传感器',
    );
    expect(result, isA<McpBridgeOk>());
    final tab = (result as McpBridgeOk).data as McpResolvedTab;
    expect(tab.id, 'a1');
  });

  test('两者矛盾', () {
    final result = resolveMcpTab(
      tabs: _tabs,
      tabId: 'a1',
      tabName: '模组',
    );
    expect(result, isA<McpBridgeErr>());
    expect((result as McpBridgeErr).code, 'tab_name_mismatch');
  });

  test('两者都空', () {
    final result = resolveMcpTab(tabs: _tabs);
    expect(result, isA<McpBridgeErr>());
    expect((result as McpBridgeErr).code, 'tab_required');
  });

  test('错误的 id', () {
    final result = resolveMcpTab(tabs: _tabs, tabId: 'nope');
    expect(result, isA<McpBridgeErr>());
    expect((result as McpBridgeErr).code, 'tab_not_found');
  });
}
