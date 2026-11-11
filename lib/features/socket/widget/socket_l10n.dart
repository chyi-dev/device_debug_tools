// I18N_KEYS: socket.menu.*, socket.kbd.*, socket.compact, socket.toolsPanel,
// socket.compactTip, socket.toolsTip, socket.conn.*, socket.log.*,
// socket.notice.*, socket.dialog.about*

import '../../../i18n/i18n.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/widget/serial_l10n.dart';
import '../model/socket_models.dart';

String socketNoticeText(Translations t, SocketNotice notice) {
  final args = notice.args;
  final n = t.socket.notice;
  return switch (notice.kind) {
    SocketNoticeKind.ready => n.ready,
    SocketNoticeKind.opened => n.opened,
    SocketNoticeKind.closed => n.closed,
    SocketNoticeKind.closedSend => n.closedSend,
    SocketNoticeKind.closedRule => n.closedRule,
    SocketNoticeKind.closedBatch => n.closedBatch,
    SocketNoticeKind.openFailed => n.openFailed(detail: args['detail'] ?? ''),
    SocketNoticeKind.badHex => t.serial.sendBox.badHex,
    SocketNoticeKind.emptySend => t.serial.sendBox.empty,
    SocketNoticeKind.noRemote => n.noRemote,
    SocketNoticeKind.noClient => n.noClient,
    SocketNoticeKind.hostInvalid => n.hostInvalid,
    SocketNoticeKind.portInvalid => n.portInvalid,
    SocketNoticeKind.timeoutInvalid => n.timeoutInvalid,
    SocketNoticeKind.periodInvalid => n.periodInvalid,
    SocketNoticeKind.repeatInvalid => n.repeatInvalid,
    SocketNoticeKind.saveStarted => n.saveStarted,
    SocketNoticeKind.saveWritten => n.saveWritten(
      name: args['name'] ?? '',
      count: args['count'] ?? 0,
    ),
    SocketNoticeKind.logSaved => n.logSaved,
    SocketNoticeKind.recvCleared => n.recvCleared,
    SocketNoticeKind.loopStarted => n.loopStarted(period: args['period'] ?? 0),
    SocketNoticeKind.loopStopped => n.loopStopped,
    SocketNoticeKind.batchRunning => n.batchRunning(
      step: args['step'] ?? 0,
      total: args['total'] ?? 0,
    ),
    SocketNoticeKind.batchEnded => n.batchEnded,
    SocketNoticeKind.ruleToggled =>
      args['enabled'] == true
          ? n.ruleOn(name: args['name'] ?? '')
          : n.ruleOff(name: args['name'] ?? ''),
    SocketNoticeKind.scriptToggled =>
      args['enabled'] == true
          ? n.ruleOn(name: args['name'] ?? '')
          : n.ruleOff(name: args['name'] ?? ''),
    SocketNoticeKind.scriptSaved => n.scriptSaved,
    SocketNoticeKind.lessonCreated => n.lessonCreated(
      title: lessonText(t, '${args['lesson'] ?? ''}').title,
      name: args['name'] ?? '',
    ),
    SocketNoticeKind.lessonTried => n.lessonTried,
    SocketNoticeKind.deleted => n.deleted,
    SocketNoticeKind.duplicated => n.duplicated,
    SocketNoticeKind.quickSaved => n.quickSaved,
    SocketNoticeKind.folderSaved => n.folderSaved,
    SocketNoticeKind.ruleSaved => n.ruleSaved,
    SocketNoticeKind.batchSaved => n.batchSaved,
    SocketNoticeKind.fileLoaded => n.fileLoaded(name: args['name'] ?? ''),
    SocketNoticeKind.peerJoined => n.peerJoined(
      address: args['address'] ?? '',
    ),
    SocketNoticeKind.peerLeft => n.peerLeft(address: args['address'] ?? ''),
    SocketNoticeKind.roleChanged => n.roleChanged,
  };
}

String socketSysText(Translations t, SocketLogLine line) {
  final args = line.args;
  final log = t.socket.log;
  final serialLog = t.serial.log;
  return switch (line.sys) {
    SysLogKind.opened => log.opened(endpoint: args['endpoint'] ?? ''),
    SysLogKind.closed => log.closedEndpoint(endpoint: args['endpoint'] ?? ''),
    SysLogKind.autoReply => serialLog.autoReply(
      name: args['name'] ?? '',
      count: args['count'] ?? 0,
    ),
    SysLogKind.replySkipped => serialLog.replySkipped(
      name: args['name'] ?? '',
      step: args['step'] ?? 0,
    ),
    SysLogKind.batchStart => serialLog.batchStart(
      name: args['name'] ?? '',
      steps: args['steps'] ?? 0,
      extra: (args['rounds'] is int && (args['rounds'] as int) > 1)
          ? serialLog.batchRounds(rounds: args['rounds'] as int)
          : '',
    ),
    SysLogKind.batchDone => serialLog.batchDone(name: args['name'] ?? ''),
    SysLogKind.batchFail => serialLog.batchFail(step: args['step'] ?? 0),
    SysLogKind.batchStopped => serialLog.batchStopped,
    SysLogKind.scriptBlocked => serialLog.scriptBlocked(
      name: args['name'] ?? '',
    ),
    SysLogKind.scriptFailed => serialLog.scriptFailed(name: args['name'] ?? ''),
    SysLogKind.mcpRejected =>
        serialLog.mcpRejected(detail: args['detail'] ?? ''),
    null => '',
  };
}
