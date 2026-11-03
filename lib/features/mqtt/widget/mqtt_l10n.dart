import '../../../i18n/i18n.dart';
import '../model/mqtt_models.dart';

String mqttNoticeText(Translations t, MqttNotice notice) {
  final n = t.mqtt.notice;
  final args = notice.args;
  return switch (notice.kind) {
    MqttNoticeKind.ready => n.ready,
    MqttNoticeKind.connected => n.connected(
      host: args['host'] ?? '',
      port: args['port'] ?? 0,
      id: args['id'] ?? '',
    ),
    MqttNoticeKind.disconnected => n.disconnected,
    MqttNoticeKind.connectFailed => n.connectFailed(
      detail: args['detail'] ?? '',
    ),
    MqttNoticeKind.closed => n.closed,
    MqttNoticeKind.closedPublish => n.closedPublish,
    MqttNoticeKind.closedSubscribe => n.closedSubscribe,
    MqttNoticeKind.needTopic => n.needTopic,
    MqttNoticeKind.dupTopic => n.dupTopic,
    MqttNoticeKind.subscribed => n.subscribed(
      topic: args['topic'] ?? '',
      qos: args['qos'] ?? 0,
    ),
    MqttNoticeKind.unsubscribed => n.unsubscribed(topic: args['topic'] ?? ''),
    MqttNoticeKind.filled => n.filled(topic: args['topic'] ?? ''),
    MqttNoticeKind.needPubTopic => n.needPubTopic,
    MqttNoticeKind.emptyPayload => n.emptyPayload,
    MqttNoticeKind.needName => n.needName,
    MqttNoticeKind.logSaved => n.logSaved,
    MqttNoticeKind.cleared => n.cleared,
    MqttNoticeKind.quickSaved => n.quickSaved,
    MqttNoticeKind.deleted => n.deleted,
    MqttNoticeKind.portInvalid => n.portInvalid,
    MqttNoticeKind.keepAliveInvalid => n.keepAliveInvalid,
  };
}

String mqttScriptLogText(Translations t, MqttScriptLogEntry entry) {
  final s = t.mqtt.script;
  return switch (entry.kind) {
    MqttScriptLogKind.output || MqttScriptLogKind.error => entry.text,
    MqttScriptLogKind.changed => s.changed(from: entry.from, to: entry.to),
    MqttScriptLogKind.blocked => s.blocked(from: entry.from),
    MqttScriptLogKind.dryRun => s.dryRun(from: entry.from, to: entry.to),
    MqttScriptLogKind.dryBlocked => s.dryBlocked(from: entry.from),
    MqttScriptLogKind.manualRx => s.manualRx(label: entry.from),
    MqttScriptLogKind.noRx => s.noRx,
    MqttScriptLogKind.badTx => s.badTx,
    MqttScriptLogKind.noHook => s.noHookLog,
    MqttScriptLogKind.tooLong => s.tooLong,
    MqttScriptLogKind.lessonTry => s.tried(
      hook: entry.text,
      sample: entry.from,
    ),
  };
}

String mqttFileLabel(Translations t, String path) {
  if (path.trim().isEmpty) return t.mqtt.unset;
  final parts = path.replaceAll('\\', '/').split('/');
  return parts.isEmpty ? path : parts.last;
}
