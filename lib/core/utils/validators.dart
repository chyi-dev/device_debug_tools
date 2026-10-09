/// 表单校验；错误文案由调用方传入已翻译的字符串。
abstract final class Validators {
  static String? required(String? value, {required String message}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? minLength(String? value, int min, {required String message}) {
    if (value == null || value.length < min) return message;
    return null;
  }
}
