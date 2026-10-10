import 'package:device_debug_tools/features/serial/data/serial_bytes.dart';
import 'package:device_debug_tools/features/serial/model/reply_lessons.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('应答教程', () {
    test('模板与正则都有课', () {
      expect(
        ReplyLesson.all.where((l) => l.kind == MatchKind.template).length,
        4,
      );
      expect(ReplyLesson.all.where((l) => l.kind == MatchKind.regex).length, 3);
    });

    test('每一课的样例帧命中，发出的字节与课上写的一致', () {
      for (final lesson in ReplyLesson.all) {
        final bytes = SerialBytes.parseHex(lesson.sample);
        expect(bytes, isNotNull, reason: lesson.key);
        final caps = SerialBytes.ruleCaptures(lesson.asRule(), bytes!);
        expect(caps, isNotNull, reason: '${lesson.key} 未命中');
        expect(
          lesson.replies.length,
          lesson.expected.length,
          reason: lesson.key,
        );
        for (var i = 0; i < lesson.replies.length; i++) {
          expect(
            SerialBytes.expandReply(lesson.replies[i].data, caps!),
            lesson.expected[i],
            reason: '${lesson.key} 第 ${i + 1} 条',
          );
        }
      }
    });

    test('四种位置表与引擎一致', () {
      final lesson = ReplyLesson.byKey('place')!;
      for (final row in lesson.modes) {
        for (final (hex, hit) in [
          (lesson.modeFrames[0], row.a),
          (lesson.modeFrames[1], row.b),
        ]) {
          expect(
            SerialBytes.ruleMatches(
              ReplyRule(
                id: 't',
                name: 't',
                match: row.mode,
                pattern: lesson.pattern,
                enabled: true,
                hits: 0,
                replies: const [],
                kind: MatchKind.template,
                format: DataFormat.hex,
              ),
              SerialBytes.parseHex(hex)!,
            ),
            hit,
            reason: '${row.mode.name} $hex',
          );
        }
      }
    });
  });
}
