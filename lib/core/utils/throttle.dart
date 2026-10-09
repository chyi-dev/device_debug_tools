typedef ThrottledCallback = void Function();

class Throttler {
  Throttler({required this.duration});

  final Duration duration;
  DateTime? _last;

  void run(ThrottledCallback action) {
    final now = DateTime.now();
    if (_last == null || now.difference(_last!) >= duration) {
      _last = now;
      action();
    }
  }
}
