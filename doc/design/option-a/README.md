# A 方案 · 原串口继承式

## 当前状态

本目录保存已选定的多协议调试工具设计稿。当前仅用于继续调整和评审，不代表 Flutter 功能已经实现。

## 文件

- `index.html`：可双击打开的单文件交互原型。
- `preview.png`：1440 × 900 预览图。

## 设计范围

- 同时管理 Serial、BLE、MQTT、WebSocket 多个连接。
- 保留现有串口工具的连接、收发、日志与发送体验。
- 每个连接独立保存快捷指令、批量发送、自动应答、历史、校验及 Lua 脚本。
- BLE、MQTT、WebSocket 具备完整连接设置和协议目标覆盖。

## 源文件

- 页面骨架：`../src/multi-pro-a.html`
- 共享样式：`../src/multi-workbench.css`
- 交互与数据：`../src/multi-workbench.js`
- 设计规格：`../multi-protocol-redesign-spec.md`

调整源文件后，在项目根目录执行：

```powershell
node doc/design/build.mjs
node doc/design/verify-multi.mjs
```

实现阶段须等待设计再次确认，不应直接依据当前稿修改 `lib/`。
