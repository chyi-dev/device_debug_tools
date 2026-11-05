import 'dart:convert';
import 'dart:io';

import 'package:device_debug_tools/features/license/data/license_codec.dart';

/// 按设备码与到期日签发激活码。
///
/// ```bash
/// dart run tool/issue_license.dart --device ABCD-EFGH-IJKL-MNOP --until 2027-11-05
/// ```
Future<void> main(List<String> args) async {
  String? device;
  String? until;
  var keyPath = 'tool/license_private_key.b64';

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--device' && i + 1 < args.length) {
      device = args[++i];
    } else if (a == '--until' && i + 1 < args.length) {
      until = args[++i];
    } else if (a == '--key' && i + 1 < args.length) {
      keyPath = args[++i];
    } else if (a == '--help' || a == '-h') {
      _usage();
      return;
    }
  }

  if (device == null || until == null) {
    _usage();
    exit(1);
  }

  final parts = until!.split('-');
  if (parts.length != 3) {
    stderr.writeln('到期日格式应为 yyyy-MM-dd');
    exit(1);
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    stderr.writeln('到期日无法解析: $until');
    exit(1);
  }
  final expires = DateTime.utc(year, month, day);

  final keyFile = File(keyPath);
  if (!keyFile.existsSync()) {
    stderr.writeln('找不到私钥: ${keyFile.path}');
    stderr.writeln('请先运行: dart run tool/generate_license_key.dart');
    exit(1);
  }
  final seedB64 = (await keyFile.readAsString()).trim();
  final seed = base64Decode(seedB64);

  final code = await LicenseCodec.issue(
    privateKeyBytes: seed,
    deviceCode: device!,
    expiresOnUtc: expires,
  );
  stdout.writeln(code);
}

void _usage() {
  stdout.writeln(
    '用法: dart run tool/issue_license.dart '
    '--device ABCD-EFGH-IJKL-MNOP --until 2027-11-05 [--key path]',
  );
}
