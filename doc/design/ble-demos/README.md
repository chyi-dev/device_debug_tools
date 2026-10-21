# 蓝牙调试 · 三版方向稿（留档）

本目录是蓝牙低功耗调试的三版对照稿，**不再作为交付入口**。用户于 2026-10-21 选定 pin（先钉再收发），正式稿在 [`../ble/`](../ble/)，规格见 [`../design.md`](../design.md) 第 10 节。

## 三版

| 文件 | 逻辑 | 骨架 | 结果 |
|---|---|---|---|
| [`pipe.html`](pipe.html) | 透传工作台 | 左扫描 / 中日志发送 / 右工具 | 未选定 |
| [`tree.html`](tree.html) | 特征表 | 左扫描 / 中 GATT 表 + 通知流 / 底栏工具 | 未选定 |
| [`pin.html`](pin.html) | 先钉再收发 | 左 GATT 钉选 / 中日志发送 / 右工具 | 已选定，拷入 `../ble/` |

截图：[`pipe.png`](pipe.png)、[`tree.png`](tree.png)、[`pin.png`](pin.png)，均为 1440×900 白底。

## 共用模拟

- 适配器就绪。扫描得到 Sensor-A4（可连）和 EnvTag-B2（拒绝连接）。
- Sensor-A4 的 GATT：Device Information（只读字符串）、Battery（读 + Notify）、自定义透传 `FFF0`（`FFF1` Notify，`FFF2` Write）。
- 透传帧与设计说明第 5 节相同。

## 怎么看

双击对应 HTML。重新截这三版：

```
node doc/design/ble-demos/shoot.mjs
```

需要本机能解析 `playwright`，默认走 Edge。选定稿的后续改动请改 [`../ble/index.html`](../ble/index.html)，不要改本目录里的 `pin.html`。
