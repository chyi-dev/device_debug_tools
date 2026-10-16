import 'connection_kind.dart';

class HomeTab {
  const HomeTab({
    required this.id,
    required this.kind,
    required this.storageKey,
    this.label,
  });

  final String id;
  final ConnectionKind kind;
  final String storageKey;

  /// 用户自定义名称。为空时界面回退到串口名。
  final String? label;

  HomeTab withLabel(String? label) {
    return HomeTab(id: id, kind: kind, storageKey: storageKey, label: label);
  }

  Map<String, Object> toJson() => {
    'id': id,
    'kind': kind.name,
    'storageKey': storageKey,
    if (label != null && label!.isNotEmpty) 'label': label!,
  };

  static HomeTab? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final kind = raw['kind'];
    final storageKey = raw['storageKey'];
    if (id is! String || id.isEmpty) return null;
    if (kind is! String) return null;
    if (storageKey is! String || storageKey.isEmpty) return null;
    final parsed = ConnectionKind.parse(kind);
    if (parsed == null || !parsed.implemented) return null;
    final label = raw['label'];
    final name = label is String ? label.trim() : '';
    return HomeTab(
      id: id,
      kind: parsed,
      storageKey: storageKey,
      label: name.isEmpty ? null : name,
    );
  }
}
