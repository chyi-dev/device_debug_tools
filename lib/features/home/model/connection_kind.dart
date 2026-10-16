/// 首页连接页签的协议。目前只有串口会真正创建会话。
enum ConnectionKind {
  serial,
  ble,
  mqtt,
  webSocket;

  static ConnectionKind? parse(String raw) {
    for (final kind in ConnectionKind.values) {
      if (kind.name == raw) return kind;
    }
    return null;
  }

  bool get implemented => this == ConnectionKind.serial;
}
