# MQTT 调试 · 三方向稿

三份稿共用 A 方案外壳和同一套演示数据，只换 MQTT 调试区骨架。已选定 inherit，见 `direction-approved.md`。选定后的改稿只动 `inherit.html`。不改 `option-a/`，也不改 Flutter。

## 文件

| 文件 | 方向 | 骨架 |
|------|------|------|
| `inherit.html` | 会话继承（已选定） | 左栏连接 / 订阅 / 发布主题列表，点「填入」写入发送区 Topic；中间日志 + 发布框；右侧快捷指令可覆盖 Topic |
| `tree.html` | 主题树 | 左侧活的主题树，中间分支报文，下方 Payload 检查（原文 / JSON / HEX） |
| `stream.html` | 报文流 | 主角是报文表，上方过滤和订阅条件条，底部发布坞 |

预览图：`inherit.png`、`tree.png`、`stream.png`（1440 × 900）。

## 共用约定

- Token 锁在 `../design.md` 白底经典；MQTT 识别色用 option-a 浅色 `--mqtt: #b86b0a`。
- 演示连接：`broker.local:1883`，MQTT 5.0，Client ID `ddt-desktop-01`。
- 演示报文：订阅 `device/+/telemetry`、`device/status`；收到遥测和 Retain 状态；发布 `device/demo/command` 后回 `device/ack`。
- 未连接时发布和订阅拦截，提示「MQTT 未连接，…已拦截」。
- MQTT 5 的 User Properties、共享订阅、主题别名不进本稿。

## 验证

```bash
node doc/design/mqtt-demos/shoot.mjs
```

需要本机可解析的 `playwright`，默认走 Edge（`PW_CHANNEL` 可改）。
