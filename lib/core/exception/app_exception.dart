/// 应用内统一异常类型，禁止在业务中吞掉异常而不处理。
sealed class AppException implements Exception {
  AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeviceException extends AppException {
  DeviceException(super.message);
}

/// 串口句柄已打开，但参数（含降级重试）未能写入驱动。
class DeviceConfigException extends DeviceException {
  DeviceConfigException(super.message);
}

class StorageException extends AppException {
  StorageException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class UnknownException extends AppException {
  UnknownException([super.message = '未知错误']);
}
