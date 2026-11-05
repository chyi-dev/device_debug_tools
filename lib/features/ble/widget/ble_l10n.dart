import '../../../i18n/i18n.dart';
import '../model/ble_models.dart';

String bleNoticeText(Translations t, BleNotice notice) {
  final n = t.ble.notice;
  final args = notice.args;
  return switch (notice.kind) {
    BleNoticeKind.ready => n.ready,
    BleNoticeKind.adapterOff => n.adapterOff,
    BleNoticeKind.scanDone => n.scanDone(count: args['count'] ?? 0),
    BleNoticeKind.scanEmpty => n.scanEmpty,
    BleNoticeKind.scanFailed => n.scanFailed(detail: args['detail'] ?? ''),
    BleNoticeKind.noDevice => n.noDevice,
    BleNoticeKind.connected => n.connected(
      name: args['name'] ?? '',
      mtu: args['mtu'] ?? 0,
    ),
    BleNoticeKind.connectFailed => n.connectFailed(
      detail: args['detail'] ?? '',
    ),
    BleNoticeKind.disconnected => n.disconnected,
    BleNoticeKind.pinNotify => n.pinNotify(uuid: args['uuid'] ?? ''),
    BleNoticeKind.unpinNotify => n.unpinNotify,
    BleNoticeKind.pinWrite => n.pinWrite(
      uuid: args['uuid'] ?? '',
      type: args['type'] ?? '',
    ),
    BleNoticeKind.unpinWrite => n.unpinWrite,
    BleNoticeKind.noWrite => n.noWrite,
    BleNoticeKind.sentNoNotify => n.sentNoNotify,
    BleNoticeKind.badHex => n.badHex,
    BleNoticeKind.emptySend => n.emptySend,
    BleNoticeKind.mtuInvalid => n.mtuInvalid,
    BleNoticeKind.chunkInvalid => n.chunkInvalid,
    BleNoticeKind.logSaved => n.logSaved,
    BleNoticeKind.recvCleared => n.recvCleared,
    BleNoticeKind.batchRunning => n.batchRunning(
      step: args['step'] ?? 0,
      total: args['total'] ?? 0,
    ),
    BleNoticeKind.batchEnded => n.batchEnded,
    BleNoticeKind.ruleOn => n.ruleOn(name: args['name'] ?? ''),
    BleNoticeKind.ruleOff => n.ruleOff(name: args['name'] ?? ''),
    BleNoticeKind.deleted => n.deleted,
    BleNoticeKind.duplicated => n.duplicated,
    BleNoticeKind.quickSaved => n.quickSaved,
    BleNoticeKind.ruleSaved => n.ruleSaved,
    BleNoticeKind.batchSaved => n.batchSaved,
    BleNoticeKind.scriptSaved => n.scriptSaved,
    BleNoticeKind.closedSend => n.closedSend,
  };
}
