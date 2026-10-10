import '../../../i18n/i18n.dart';
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
    null => '',
  };
}

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
