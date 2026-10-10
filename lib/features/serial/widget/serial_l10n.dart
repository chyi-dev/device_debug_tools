import '../../../i18n/i18n.dart';
import '../model/reply_lessons.dart';
import '../model/serial_models.dart';

String serialNoticeText(Translations t, SerialNotice notice) {
  final args = notice.args;
  final n = t.serial.notice;
  return switch (notice.kind) {
    SerialNoticeKind.ready => n.ready,
    SerialNoticeKind.portOpened => n.portOpened,
    SerialNoticeKind.portClosed => n.portClosed,
    SerialNoticeKind.portClosedSend => n.portClosedSend,
    SerialNoticeKind.portClosedRule => n.portClosedRule,
    SerialNoticeKind.portClosedBatch => n.portClosedBatch,
    SerialNoticeKind.noPort => n.noPort,
    SerialNoticeKind.portBusy => n.portBusy,
    SerialNoticeKind.openFailed => n.openFailed(detail: args['detail'] ?? ''),
    SerialNoticeKind.configFailed => n.configFailed(
      detail: args['detail'] ?? '',
    ),
    SerialNoticeKind.configPartial => n.configPartial,
    SerialNoticeKind.baudInvalid => n.baudInvalid,
    SerialNoticeKind.timeoutInvalid => n.timeoutInvalid,
    SerialNoticeKind.periodInvalid => n.periodInvalid,
    SerialNoticeKind.repeatInvalid => n.repeatInvalid,
    SerialNoticeKind.scanDone => n.scanDone(count: args['count'] ?? 0),
    SerialNoticeKind.paramsApplied => n.paramsApplied(conn: args['conn'] ?? ''),
    SerialNoticeKind.timeoutHint => n.timeoutHint(ms: args['ms'] ?? 0),
    SerialNoticeKind.timeoutSplitHint => n.timeoutSplitHint,
    SerialNoticeKind.saveStarted => n.saveStarted,
    SerialNoticeKind.saveWritten => n.saveWritten(
      name: args['name'] ?? '',
      count: args['count'] ?? 0,
    ),
    SerialNoticeKind.saveCancelled => n.ready,
    SerialNoticeKind.logSaved => n.logSaved,
    SerialNoticeKind.recvCleared => n.recvCleared,
    SerialNoticeKind.loopStarted => n.loopStarted(period: args['period'] ?? 0),
    SerialNoticeKind.loopStopped => n.loopStopped,
    SerialNoticeKind.batchRunning => n.batchRunning(
      step: args['step'] ?? 0,
      total: args['total'] ?? 0,
    ),
    SerialNoticeKind.batchEnded => n.batchEnded,
    SerialNoticeKind.ruleToggled =>
      args['enabled'] == true
          ? n.ruleOn(name: args['name'] ?? '')
          : n.ruleOff(name: args['name'] ?? ''),
    SerialNoticeKind.scriptToggled =>
      args['enabled'] == true
          ? n.ruleOn(name: args['name'] ?? '')
          : n.ruleOff(name: args['name'] ?? ''),
    SerialNoticeKind.scriptSaved => n.scriptSaved,
    SerialNoticeKind.lessonCreated => n.lessonCreated(
      title: lessonText(t, '${args['lesson'] ?? ''}').title,
      name: args['name'] ?? '',
    ),
    SerialNoticeKind.lessonTried => n.lessonTried,
    SerialNoticeKind.deleted => n.deleted,
    SerialNoticeKind.quickSaved => n.quickSaved,
    SerialNoticeKind.folderSaved => n.folderSaved,
    SerialNoticeKind.ruleSaved => n.ruleSaved,
    SerialNoticeKind.batchSaved => n.batchSaved,
    SerialNoticeKind.checksumFilled => n.checksumFilled(
      text: args['text'] ?? '',
    ),
    SerialNoticeKind.exportedQuick => n.exportedQuick,
    SerialNoticeKind.exportedRules => n.exportedRules,
    SerialNoticeKind.imported => n.imported(count: args['count'] ?? 0),
    SerialNoticeKind.importInvalid => n.importInvalid,
    SerialNoticeKind.fileLoaded => n.fileLoaded(name: args['name'] ?? ''),
    SerialNoticeKind.badHex => t.serial.sendBox.badHex,
    SerialNoticeKind.emptySend => t.serial.sendBox.empty,
  };
}

String serialSysText(Translations t, LogLine line) {
  final args = line.args;
  final log = t.serial.log;
  return switch (line.sys) {
    SysLogKind.opened => log.opened(
      port: args['port'] ?? '',
      baud: args['baud'] ?? '',
      frame: args['frame'] ?? '',
    ),
    SysLogKind.closed => log.closedPort(port: args['port'] ?? ''),
    SysLogKind.autoReply => log.autoReply(
      name: args['name'] ?? '',
      count: args['count'] ?? 0,
    ),
    SysLogKind.replySkipped => log.replySkipped(
      name: args['name'] ?? '',
      step: args['step'] ?? 0,
    ),
    SysLogKind.batchStart => log.batchStart(
      name: args['name'] ?? '',
      steps: args['steps'] ?? 0,
      extra: (args['rounds'] is int && (args['rounds'] as int) > 1)
          ? log.batchRounds(rounds: args['rounds'] as int)
          : '',
    ),
    SysLogKind.batchDone => log.batchDone(name: args['name'] ?? ''),
    SysLogKind.batchFail => log.batchFail(step: args['step'] ?? 0),
    SysLogKind.batchStopped => log.batchStopped,
    SysLogKind.scriptBlocked => log.scriptBlocked(name: args['name'] ?? ''),
    SysLogKind.scriptFailed => log.scriptFailed(name: args['name'] ?? ''),
    null => '',
  };
}

String scriptLogText(Translations t, ScriptLogEntry entry) {
  final s = t.serial.script;
  return switch (entry.kind) {
    ScriptLogKind.output || ScriptLogKind.error => entry.text,
    ScriptLogKind.changed => s.changed(from: entry.from, to: entry.to),
    ScriptLogKind.blocked => s.blocked(from: entry.from),
    ScriptLogKind.dryRun => s.dryRun(from: entry.from, to: entry.to),
    ScriptLogKind.dryBlocked => s.dryBlocked(from: entry.from),
    ScriptLogKind.manualRx => s.manualRx(hex: entry.from),
    ScriptLogKind.noRx => s.noRx,
    ScriptLogKind.badTx => s.badTx,
    ScriptLogKind.noHook => s.noHookLog,
    ScriptLogKind.tooLong => s.tooLong,
    ScriptLogKind.lessonTry => s.tried(hook: entry.text, hex: entry.from),
  };
}

/// 应答课表一课的文案；key 见 `ReplyLesson.key`。
({String title, String brief, String text, String name, String rxNote})
replyLessonCopy(Translations t, String key) {
  final l = t.serial.reply.lessons;
  return switch (key) {
    'order' => (
      title: l.order.title,
      brief: l.order.brief,
      text: l.order.text,
      name: l.order.name,
      rxNote: l.order.rxNote,
    ),
    'place' => (
      title: l.place.title,
      brief: l.place.brief,
      text: l.place.text,
      name: l.place.name,
      rxNote: l.place.rxNote,
    ),
    'wild' => (
      title: l.wild.title,
      brief: l.wild.brief,
      text: l.wild.text,
      name: l.wild.name,
      rxNote: l.wild.rxNote,
    ),
    'ascii' => (
      title: l.ascii.title,
      brief: l.ascii.brief,
      text: l.ascii.text,
      name: l.ascii.name,
      rxNote: l.ascii.rxNote,
    ),
    'reword' => (
      title: l.reword.title,
      brief: l.reword.brief,
      text: l.reword.text,
      name: l.reword.name,
      rxNote: l.reword.rxNote,
    ),
    'groups' => (
      title: l.groups.title,
      brief: l.groups.brief,
      text: l.groups.text,
      name: l.groups.name,
      rxNote: l.groups.rxNote,
    ),
    'reascii' => (
      title: l.reascii.title,
      brief: l.reascii.brief,
      text: l.reascii.text,
      name: l.reascii.name,
      rxNote: l.reascii.rxNote,
    ),
    _ => (title: key, brief: '', text: '', name: key, rxNote: ''),
  };
}

/// 字节格下方的短标签。捕获格直接显示 `$n`。
String replyByteTag(Translations t, ReplyByte byte) {
  final r = t.serial.reply;
  return switch (byte.role) {
    ReplyByteRole.capture => '\$${byte.cap}',
    ReplyByteRole.fixed => r.tagFixed,
    ReplyByteRole.ignore => r.tagIgnore,
    ReplyByteRole.prefix => r.prefix,
    ReplyByteRole.match => r.tagMatch,
    ReplyByteRole.before => r.tagBefore,
    ReplyByteRole.literal => r.tagLiteral,
  };
}

/// 课表里那一行匹配式，如「整帧 HEX · A5 ?? *」。
String replyRecipe(Translations t, ReplyLesson lesson) {
  final r = t.serial.reply;
  final format = lesson.format == DataFormat.ascii ? 'ASCII' : 'HEX';
  if (lesson.kind == MatchKind.regex) {
    return '${r.regex} $format · ${lesson.pattern}';
  }
  final fold = lesson.format == DataFormat.ascii && lesson.ignoreCase
      ? ' ${r.ignoreCaseShort}'
      : '';
  return '${matchModeLabel(t, lesson.match)} $format$fold · ${lesson.pattern}';
}

/// 教程一课的标题、一句话概要与说明；key 见 `ScriptLesson.key`。
({String title, String brief, String text}) lessonText(
  Translations t,
  String key,
) {
  final l = t.serial.script.lessons;
  return switch (key) {
    'hooks' => (title: l.hooks.title, brief: l.hooks.brief, text: l.hooks.text),
    'print' => (title: l.print.title, brief: l.print.brief, text: l.print.text),
    'parse' => (title: l.parse.title, brief: l.parse.brief, text: l.parse.text),
    'checksum' => (
      title: l.checksum.title,
      brief: l.checksum.brief,
      text: l.checksum.text,
    ),
    'block' => (title: l.block.title, brief: l.block.brief, text: l.block.text),
    'modbus' => (
      title: l.modbus.title,
      brief: l.modbus.brief,
      text: l.modbus.text,
    ),
    _ => (title: key, brief: '', text: ''),
  };
}

String scriptHookName(ScriptHook hook) => switch (hook) {
  ScriptHook.onReceive => 'on_receive',
  ScriptHook.beforeSend => 'before_send',
};

String encodeErrorText(Translations t, EncodeError error) => switch (error) {
  EncodeError.badHex => t.serial.sendBox.badHex,
  EncodeError.empty => t.serial.sendBox.empty,
};

String matchModeLabel(Translations t, MatchMode mode) => switch (mode) {
  MatchMode.prefix => t.serial.reply.prefix,
  MatchMode.frame => t.serial.reply.frame,
  MatchMode.contains => t.serial.reply.contains,
  MatchMode.suffix => t.serial.reply.suffix,
};

/// 列表行里的匹配说明，如「前缀 HEX A5 5A ??」「正则 ASCII ^OK」。
String ruleMatchLabel(Translations t, ReplyRule rule) {
  final format = rule.format == DataFormat.hex ? 'HEX' : 'ASCII';
  final head = rule.kind == MatchKind.regex
      ? t.serial.reply.regex
      : matchModeLabel(t, rule.match);
  final flag = rule.format == DataFormat.ascii && rule.ignoreCase
      ? ' ${t.serial.reply.ignoreCaseShort}'
      : '';
  return '$head $format$flag ${rule.pattern}';
}

String checksumLabel(Translations t, ChecksumKind kind) => switch (kind) {
  ChecksumKind.none => t.serial.flowOpt.none,
  ChecksumKind.sum => t.serial.checksum.sum,
  ChecksumKind.xor => t.serial.checksum.xor,
  ChecksumKind.lrc => t.serial.checksum.lrc,
  ChecksumKind.crc8 => t.serial.checksum.crc8,
  ChecksumKind.crc16 => t.serial.checksum.crc16,
  ChecksumKind.crc32 => t.serial.checksum.crc32,
};
