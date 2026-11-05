import 'package:file_selector/file_selector.dart';

import '../../serial/data/file_selector_gateway.dart';
import '../../serial/data/serial_file_gateway.dart';

class MqttFileGateway {
  MqttFileGateway({SerialFileGateway? files})
    : _files = files ?? FileSelectorGateway();

  final SerialFileGateway _files;

  Future<String?> pickPath({List<String> extensions = const []}) async {
    final file = await openFile(
      acceptedTypeGroups: extensions.isEmpty
          ? const []
          : [XTypeGroup(extensions: extensions)],
    );
    return file?.path;
  }

  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) => _files.pickSave(suggestedName: suggestedName, extension: extension);

  Future<void> writeText({required String path, required String text}) =>
      _files.writeText(path: path, text: text);
}
