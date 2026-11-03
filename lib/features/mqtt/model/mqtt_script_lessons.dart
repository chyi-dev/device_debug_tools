import 'mqtt_models.dart';

/// 脚本页「教程」的一课。标题说明走 slang `mqtt.script.lessons.<key>`，
/// 代码与样例消息不翻译，且只能用引擎 prelude 已有的 `log`。
class MqttScriptLesson {
  const MqttScriptLesson({
    required this.key,
    required this.fileName,
    required this.hook,
    required this.code,
    required this.sampleTopic,
    required this.samplePayload,
    this.sampleQos = 0,
    this.sampleRetain = false,
  });

  final String key;
  final String fileName;
  final MqttScriptHook hook;
  final String code;
  final String sampleTopic;
  final String samplePayload;
  final int sampleQos;
  final bool sampleRetain;

  String get hookName => switch (hook) {
    MqttScriptHook.onMessage => 'on_message',
    MqttScriptHook.beforePublish => 'before_publish',
  };

  MqttScriptMessage get sample => MqttScriptMessage(
    topic: sampleTopic,
    payload: samplePayload,
    qos: sampleQos,
    retain: sampleRetain,
  );

  static const all = [
    MqttScriptLesson(
      key: 'hooks',
      fileName: 'lesson1_hooks.lua',
      hook: MqttScriptHook.onMessage,
      sampleTopic: 'device/status',
      samplePayload: 'online',
      sampleQos: 1,
      sampleRetain: true,
      code:
          '-- 报文写入日志之后运行。msg 是 {topic, payload, qos, retain}\n'
          'function on_message(msg)\n'
          '  log("收到", msg.topic)\n'
          'end\n',
    ),
    MqttScriptLesson(
      key: 'print',
      fileName: 'lesson2_print.lua',
      hook: MqttScriptHook.onMessage,
      sampleTopic: 'device/room1/telemetry',
      samplePayload: '{"temp":23.4}',
      sampleQos: 1,
      code:
          'function on_message(msg)\n'
          '  log(msg.topic, msg.payload)\n'
          'end\n',
    ),
    MqttScriptLesson(
      key: 'rewrite',
      fileName: 'lesson3_rewrite.lua',
      hook: MqttScriptHook.beforePublish,
      sampleTopic: 'device/demo/command',
      samplePayload: 'led',
      sampleQos: 1,
      code:
          '-- 返回改写后的表才会发出；返回 nil 则这一次不发\n'
          'function before_publish(msg)\n'
          '  if msg.payload == "drop" then return nil end\n'
          '  msg.payload = "cmd:" .. msg.payload\n'
          '  return msg\n'
          'end\n',
    ),
  ];
}
