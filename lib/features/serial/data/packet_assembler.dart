import 'dart:async';
import 'dart:typed_data';

/// 同一超时窗口内到达的字节合并为一条记录。
class PacketAssembler {
  final List<int> _buffer = [];
  Timer? _timer;

  void add(List<int> chunk, int timeoutMs, void Function(Uint8List bytes) onPacket) {
    if (chunk.isEmpty) return;
    _buffer.addAll(chunk);
    _timer?.cancel();
    _timer = Timer(
      Duration(milliseconds: timeoutMs < 0 ? 0 : timeoutMs),
      () => flush(onPacket),
    );
  }

  void flush(void Function(Uint8List bytes) onPacket) {
    _timer?.cancel();
    _timer = null;
    if (_buffer.isEmpty) return;
    final bytes = Uint8List.fromList(_buffer);
    _buffer.clear();
    onPacket(bytes);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _buffer.clear();
  }
}
