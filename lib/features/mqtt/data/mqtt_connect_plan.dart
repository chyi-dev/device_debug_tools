import '../model/mqtt_models.dart';

/// 由协议选项得到的建连参数。不含套接字或证书内容。
class MqttConnectPlan {
  const MqttConnectPlan({
    required this.server,
    required this.useWebSocket,
    required this.secure,
    required this.alternateWebSocket,
  });

  /// TCP 时为主机名；WebSocket 时为带 scheme 与路径、不含端口的 URI。
  final String server;
  final bool useWebSocket;

  /// 仅 mqtts 为 true。wss 不能设 secure，否则 mqtt_client 会关掉 WebSocket。
  final bool secure;

  /// 仅 wss 且配置了自定义证书时为 true。
  final bool alternateWebSocket;

  static MqttConnectPlan resolve(MqttLinkConfig config) {
    switch (config.scheme) {
      case MqttScheme.mqtt:
        return MqttConnectPlan(
          server: config.host,
          useWebSocket: false,
          secure: false,
          alternateWebSocket: false,
        );
      case MqttScheme.mqtts:
        return MqttConnectPlan(
          server: config.host,
          useWebSocket: false,
          secure: true,
          alternateWebSocket: false,
        );
      case MqttScheme.ws:
      case MqttScheme.wss:
        return MqttConnectPlan(
          server: _websocketServer(config),
          useWebSocket: true,
          secure: false,
          alternateWebSocket:
              config.scheme == MqttScheme.wss && config.hasCustomCerts,
        );
    }
  }

  static String _websocketServer(MqttLinkConfig config) {
    final scheme = config.scheme == MqttScheme.wss ? 'wss' : 'ws';
    return '$scheme://${config.host}${normalizeWsPath(config.wsPath)}';
  }
}
