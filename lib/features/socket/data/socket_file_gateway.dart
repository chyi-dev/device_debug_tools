import '../../serial/data/file_selector_gateway.dart';
import '../../serial/data/serial_file_gateway.dart';
import '../../serial/model/serial_models.dart';

class SocketFileGateway {
  SocketFileGateway({SerialFileGateway? files})
    : _files = files ?? FileSelectorGateway();

  final SerialFileGateway _files;

  Future<PickedBytes?> pickAny() => _files.pickAny();

  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) => _files.pickSave(suggestedName: suggestedName, extension: extension);

  Future<void> writeText({required String path, required String text}) =>
      _files.writeText(path: path, text: text);
}
