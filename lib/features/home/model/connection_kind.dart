/// 首页连接页签的协议。
enum ConnectionKind {
  serial,
  ble,
  mqtt;

  static ConnectionKind? parse(String raw) {
    for (final kind in ConnectionKind.values) {
      if (kind.name == raw) return kind;
    }
    return null;
  }
}
