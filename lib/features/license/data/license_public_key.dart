import 'dart:convert';

/// 应用内嵌 Ed25519 公钥（Base64）。私钥仅保存在签发者本机。
abstract final class LicensePublicKey {
  static const String base64 = 'DZkKFGJFCLtIS34AjGD02s7FWUdc3zgizBjuL8QHs6c=';

  static List<int> get bytes => base64Decode(base64);
}
