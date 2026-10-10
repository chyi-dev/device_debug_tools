import 'serial_models.dart';

/// 配置包里可单独勾选的四类用户内容。
enum ConfigPart { quick, rules, batch, scripts }

/// 快捷指令 / 自动应答 / 批量发送 / 脚本的导入导出文件；为 null 的类别表示文件里没有。
class ConfigPack {
  const ConfigPack({
    this.quick,
    this.rules,
    this.batch,
    this.scripts,
    this.legacy = false,
  });

  static const kind = 'device-debug-config';
  static const version = 1;
  static const fileName = 'device-debug-config.json';

  final List<QuickNode>? quick;
  final List<ReplyRule>? rules;
  final List<BatchJob>? batch;
  final List<LuaScript>? scripts;

  /// 读自旧的单列表文件（以前导出的快捷指令或应答规则数组）。
  final bool legacy;

  Set<ConfigPart> get parts => {
    if (quick != null) ConfigPart.quick,
    if (rules != null) ConfigPart.rules,
    if (batch != null) ConfigPart.batch,
    if (scripts != null) ConfigPart.scripts,
  };

  /// 快捷指令按指令条数算，文件夹不计。
  int? count(ConfigPart part) => switch (part) {
    ConfigPart.quick => quick?.commands.length,
    ConfigPart.rules => rules?.length,
    ConfigPart.batch => batch?.length,
    ConfigPart.scripts => scripts?.length,
  };

  int get enabledScripts => scripts?.where((s) => s.enabled).length ?? 0;

  /// 命中次数是运行统计，不写进文件。
  Map<String, Object> toJson(Set<ConfigPart> only) => {
    'kind': kind,
    'version': version,
    if (only.contains(ConfigPart.quick) && quick != null)
      'quick': quick!.map((q) => q.toJson()).toList(),
    if (only.contains(ConfigPart.rules) && rules != null)
      'rules': rules!.map((r) => r.toJson()..remove('hits')).toList(),
    if (only.contains(ConfigPart.batch) && batch != null)
      'batch': batch!.map((b) => b.toJson()).toList(),
    if (only.contains(ConfigPart.scripts) && scripts != null)
      'scripts': scripts!.map((s) => s.toJson()).toList(),
  };

  /// 认不出、或任一条解析失败时返回 null。
  static ConfigPack? fromJson(Object? raw) {
    if (raw is List) return _legacy(raw);
    if (raw is! Map || raw['kind'] != kind) return null;
    final present = [
      for (final key in const ['quick', 'rules', 'batch', 'scripts'])
        if (raw.containsKey(key)) key,
    ];
    if (present.isEmpty) return null;
    if (present.any((key) => raw[key] is! List)) return null;
    final quick = _all(raw['quick'], QuickNode.fromJson);
    final rules = _all(raw['rules'], ReplyRule.fromJson);
    final batch = _all(raw['batch'], BatchJob.fromJson);
    final scripts = _all(raw['scripts'], LuaScript.fromJson);
    final failed = [
      (raw.containsKey('quick'), quick),
      (raw.containsKey('rules'), rules),
      (raw.containsKey('batch'), batch),
      (raw.containsKey('scripts'), scripts),
    ].any((item) => item.$1 && item.$2 == null);
    if (failed) return null;
    return ConfigPack(
      quick: quick,
      rules: rules,
      batch: batch,
      scripts: scripts,
    );
  }

  /// 旧文件按首项形状认类别：steps 为批量、code 为脚本、pattern/replies 为应答，其余为快捷指令。
  static ConfigPack? _legacy(List<Object?> raw) {
    final first = raw.isEmpty ? null : raw.first;
    if (first is! Map) return null;
    if (first['steps'] is List) {
      final list = _all(raw, BatchJob.fromJson);
      return list == null ? null : ConfigPack(batch: list, legacy: true);
    }
    if (first['code'] is String) {
      final list = _all(raw, LuaScript.fromJson);
      return list == null ? null : ConfigPack(scripts: list, legacy: true);
    }
    if (first.containsKey('pattern') || first['replies'] is List) {
      final list = _all(raw, ReplyRule.fromJson);
      return list == null ? null : ConfigPack(rules: list, legacy: true);
    }
    final list = _all(raw, QuickNode.fromJson);
    return list == null ? null : ConfigPack(quick: list, legacy: true);
  }

  static List<T>? _all<T>(Object? raw, T? Function(Object? item) parse) {
    if (raw is! List) return null;
    final out = <T>[];
    for (final item in raw) {
      final parsed = parse(item);
      if (parsed == null) return null;
      out.add(parsed);
    }
    return out;
  }
}
