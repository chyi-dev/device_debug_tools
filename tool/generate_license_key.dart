import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

/// 首次生成 Ed25519 密钥对：私钥写入本地文件，公钥打印到终端。
///
/// ```bash
/// dart run tool/generate_license_key.dart
/// ```
Future<void> main(List<String> args) async {
  final outPath = args.isNotEmpty ? args.first : 'tool/license_private_key.b64';
  final file = File(outPath);
  if (file.existsSync()) {
    stderr.writeln('私钥已存在: ${file.path}');
    stderr.writeln('若要重新生成，请先删除该文件。');
    exit(1);
  }

  final pair = await Ed25519().newKeyPair();
  final simple = await pair.extract() as SimpleKeyPairData;
  final pub = await simple.extractPublicKey();
  final seedB64 = base64Encode(simple.bytes);
  final pubB64 = base64Encode(pub.bytes);

  await file.parent.create(recursive: true);
  await file.writeAsString('$seedB64\n');

  stdout.writeln('私钥已写入: ${file.absolute.path}');
  stdout.writeln('请将下列公钥写入 lib/features/license/data/license_public_key.dart：');
  stdout.writeln();
  stdout.writeln(pubB64);
}
