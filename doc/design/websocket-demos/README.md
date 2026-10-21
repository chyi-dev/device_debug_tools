# WebSocket 调试 · 三版布局稿

当前阶段只出设计，不改 `lib/`，也不改已选定的 [`../option-a/`](../option-a/)。

A 方案已经能建一条 WebSocket 连接，但日志仍是串口式 `RECV/SEND` 文本，看不出 opcode、握手 101、Ping/Pong 和 Close code。这三版把「帧」做成可点的界面，方便选定后再实现。

视觉锁在 [`../design.md`](../design.md)：白底/黑底经典、唯一强调色 `accent`、绿/红只表示连接状态。`--ws` 只做标签上的小标记。

## 三版

同一条会话：`ws://10.0.0.8:8080/debug`，子协议 `device-v1`。都能连接、发 Text / Binary / Ping、带 code 与 reason 的关闭帧；未连接时发送会拦截。

| 文件 | 骨架 | 适合看什么 |
|------|------|------------|
| [`log.html`](log.html) | 左设置 · 中两行帧日志 · 右快捷指令 | 最接近现有串口台。提示符写成 `[时间]# RECV TEXT>` |
| [`inspect.html`](inspect.html) | 左设置 · 上帧表 · 下载荷 Text/JSON/HEX | 点一行才看载荷 |
| [`session.html`](session.html) | 标签下握手条 · 全部/数据/控制过滤 | 握手 101 与 Ping/Pong/Close 和业务帧分开 |

预览（1440 × 900）：[`log.png`](log.png)、[`inspect.png`](inspect.png)、[`session.png`](session.png)。

## 和 A 方案的关系

快捷指令、批量、自动应答、Lua 仍以 A 方案为准，这里只留一个短快捷列表。左栏连接项与规格一致：URL、Headers、Subprotocol、代理、TLS、压缩、Ping、自动重连、默认帧类型。

## 状态

尚未选定，不要按本稿改 Flutter。选定后把原话写入 [`../direction-approved.md`](../direction-approved.md)。
