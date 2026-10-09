import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../model/serial_models.dart';
import 'serial_file_gateway.dart';

class FileSelectorGateway implements SerialFileGateway {
  @override
  Future<PickedBytes?> pickAny() async {
    final file = await openFile();
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedBytes(name: file.name, bytes: bytes);
  }

  @override
  Future<String?> pickText({required List<String> extensions}) async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(extensions: extensions),
      ],
    );
    if (file == null) return null;
    return file.readAsString();
  }

  @override
  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        XTypeGroup(extensions: [extension]),
      ],
    );
    return location?.path;
  }

  @override
  Future<void> writeText({required String path, required String text}) async {
    try {
      await File(path).writeAsString(text, encoding: utf8);
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '写出文件失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      throw StorageException('$error');
    }
  }
}
