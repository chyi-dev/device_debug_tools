import '../model/serial_models.dart';

abstract class SerialFileGateway {
  Future<PickedBytes?> pickAny();

  Future<String?> pickText({required List<String> extensions});

  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  });

  Future<void> writeText({required String path, required String text});
}
