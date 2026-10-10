import 'serial_models.dart';

/// 应答规则编辑器右侧课表的一课。
/// 标题、说明、填入用的规则名走 slang（`serial.reply.lessons.<key>`）；
/// 匹配式、样例帧和应答不翻译，并且必须能被 [SerialBytes.ruleCaptures] 跑通。
class ReplyLesson {
  const ReplyLesson({
    required this.key,
    required this.kind,
    required this.format,
    required this.match,
    required this.pattern,
    required this.replies,
    required this.sample,
    required this.expected,
    required this.rx,
    this.ignoreCase = false,
    this.modeFrames = const [],
    this.modes = const [],
  });

  final String key;
  final MatchKind kind;
  final DataFormat format;
  final MatchMode match;
  final String pattern;
  final bool ignoreCase;
  final List<ReplyStep> replies;

  /// 样例帧，HEX。ASCII 课也用字节的 HEX，显示用 [rx]。
  final String sample;

  /// 与 [replies] 一一对应的发出结果（HEX）。
  final List<String> expected;
  final List<ReplyByte> rx;

  /// 「四种位置」对照用的两帧 HEX；其他课为空。
  final List<String> modeFrames;
  final List<ReplyModeHit> modes;

  ReplyRule asRule() => ReplyRule(
    id: 'lesson-$key',
    name: key,
    match: match,
    pattern: pattern,
    enabled: true,
    hits: 0,
    replies: replies,
    kind: kind,
    format: format,
    ignoreCase: ignoreCase,
  );

  static const all = [
    ReplyLesson(
      key: 'order',
      kind: MatchKind.template,
      format: DataFormat.hex,
      match: MatchMode.prefix,
      pattern: 'A5 5A',
      sample: 'A5 5A 01 02',
      replies: [
        ReplyStep(data: 'A5 81', delayMs: 20),
        ReplyStep(data: 'A5 5A 00', delayMs: 50),
      ],
      expected: ['A5 81', 'A5 5A 00'],
      rx: [
        ReplyByte('A5', ReplyByteRole.prefix),
        ReplyByte('5A', ReplyByteRole.prefix),
        ReplyByte('01', ReplyByteRole.ignore, dim: true),
        ReplyByte('02', ReplyByteRole.ignore, dim: true),
      ],
    ),
    ReplyLesson(
      key: 'place',
      kind: MatchKind.template,
      format: DataFormat.hex,
      match: MatchMode.contains,
      pattern: 'A5 5A',
      sample: '00 A5 5A',
      replies: [ReplyStep(data: 'A5 90', delayMs: 0)],
      expected: ['A5 90'],
      modeFrames: ['A5 5A 03 00', '00 A5 5A'],
      modes: [
        ReplyModeHit(MatchMode.prefix, true, false),
        ReplyModeHit(MatchMode.contains, true, true),
        ReplyModeHit(MatchMode.frame, false, false),
        ReplyModeHit(MatchMode.suffix, false, true),
      ],
      rx: [
        ReplyByte('00', ReplyByteRole.before, dim: true),
        ReplyByte('A5', ReplyByteRole.match),
        ReplyByte('5A', ReplyByteRole.match),
      ],
    ),
    ReplyLesson(
      key: 'wild',
      kind: MatchKind.template,
      format: DataFormat.hex,
      match: MatchMode.frame,
      pattern: 'A5 ?? *',
      sample: 'A5 11 22 33',
      replies: [
        ReplyStep(data: 'B0 \$1', delayMs: 10),
        ReplyStep(data: '\$2', delayMs: 10),
      ],
      expected: ['B0 11', '22 33'],
      rx: [
        ReplyByte('A5', ReplyByteRole.fixed),
        ReplyByte('11', ReplyByteRole.capture, cap: 1),
        ReplyByte('22', ReplyByteRole.capture, cap: 2),
        ReplyByte('33', ReplyByteRole.capture, cap: 2),
      ],
    ),
    ReplyLesson(
      key: 'ascii',
      kind: MatchKind.template,
      format: DataFormat.ascii,
      match: MatchMode.prefix,
      pattern: 'OK,?',
      ignoreCase: true,
      sample: '6F 6B 2C 37',
      replies: [ReplyStep(data: '\$1', delayMs: 30)],
      expected: ['37'],
      rx: [
        ReplyByte('o', ReplyByteRole.fixed),
        ReplyByte('k', ReplyByteRole.fixed),
        ReplyByte(',', ReplyByteRole.fixed),
        ReplyByte('7', ReplyByteRole.capture, cap: 1),
      ],
    ),
    ReplyLesson(
      key: 'reword',
      kind: MatchKind.regex,
      format: DataFormat.hex,
      match: MatchMode.prefix,
      pattern: r'^A5 5A ([0-9A-F]{2})',
      sample: 'A5 5A 03',
      replies: [ReplyStep(data: 'A5 \$1', delayMs: 40)],
      expected: ['A5 03'],
      rx: [
        ReplyByte('A5', ReplyByteRole.literal),
        ReplyByte('5A', ReplyByteRole.literal),
        ReplyByte('03', ReplyByteRole.capture, cap: 1),
      ],
    ),
    ReplyLesson(
      key: 'groups',
      kind: MatchKind.regex,
      format: DataFormat.hex,
      match: MatchMode.frame,
      pattern: r'^A5 5A ([0-9A-F]{2}) ([0-9A-F]{2})$',
      sample: 'A5 5A 11 22',
      replies: [
        ReplyStep(data: 'B1 \$1', delayMs: 20),
        ReplyStep(data: 'B2 \$2', delayMs: 20),
      ],
      expected: ['B1 11', 'B2 22'],
      rx: [
        ReplyByte('A5', ReplyByteRole.literal),
        ReplyByte('5A', ReplyByteRole.literal),
        ReplyByte('11', ReplyByteRole.capture, cap: 1),
        ReplyByte('22', ReplyByteRole.capture, cap: 2),
      ],
    ),
    ReplyLesson(
      key: 'reascii',
      kind: MatchKind.regex,
      format: DataFormat.ascii,
      match: MatchMode.prefix,
      pattern: r'^OK,(.+)$',
      sample: '4F 4B 2C 34 32',
      replies: [ReplyStep(data: '\$1', delayMs: 20)],
      expected: ['34 32'],
      rx: [
        ReplyByte('O', ReplyByteRole.literal),
        ReplyByte('K', ReplyByteRole.literal),
        ReplyByte(',', ReplyByteRole.literal),
        ReplyByte('4', ReplyByteRole.capture, cap: 1),
        ReplyByte('2', ReplyByteRole.capture, cap: 1),
      ],
    ),
  ];

  static ReplyLesson? byKey(String key) {
    for (final lesson in all) {
      if (lesson.key == key) return lesson;
    }
    return null;
  }
}

enum ReplyByteRole { fixed, ignore, prefix, match, before, literal, capture }

class ReplyByte {
  const ReplyByte(this.text, this.role, {this.dim = false, this.cap});

  final String text;
  final ReplyByteRole role;
  final bool dim;

  /// [ReplyByteRole.capture] 时的 `$n`，从 1 起。
  final int? cap;
}

class ReplyModeHit {
  const ReplyModeHit(this.mode, this.a, this.b);

  final MatchMode mode;
  final bool a;
  final bool b;
}
