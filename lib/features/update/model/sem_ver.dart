/// 仅比较 `x.y.z`；忽略前缀 `v` 与 `+build`。
class SemVer implements Comparable<SemVer> {
  const SemVer(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  /// 解析失败返回 `null`。
  static SemVer? tryParse(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    final plus = s.indexOf('+');
    if (plus >= 0) s = s.substring(0, plus);
    final dash = s.indexOf('-');
    if (dash >= 0) s = s.substring(0, dash);
    final parts = s.split('.');
    if (parts.length < 2 || parts.length > 3) return null;
    final major = int.tryParse(parts[0]);
    final minor = int.tryParse(parts[1]);
    final patch = parts.length == 3 ? int.tryParse(parts[2]) : 0;
    if (major == null || minor == null || patch == null) return null;
    if (major < 0 || minor < 0 || patch < 0) return null;
    return SemVer(major, minor, patch);
  }

  /// 规范化展示用版本号（无 `v`、无 build）。
  static String? normalize(String input) {
    final v = tryParse(input);
    if (v == null) return null;
    return v.toString();
  }

  /// 当前版本是否严格小于远端。
  static bool isNewer(String remote, String current) {
    final r = tryParse(remote);
    final c = tryParse(current);
    if (r == null || c == null) return false;
    return r.compareTo(c) > 0;
  }

  @override
  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) =>
      other is SemVer &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}
