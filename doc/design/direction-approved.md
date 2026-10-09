# 设计方向确认

## 最终结论

> 最终采用 D:\workspace\demo\device_debug_tools\doc\design\serial-console.html ，其他设计可以删除

设计说明见 `design.md`，对应规则见 `.cursor/rules/serial-console.mdc`。

## 曾展示的三版初稿（已删除）

| 逻辑 | 文件 |
|---|---|
| 秒数轮盘 05 → 网页 6 号「巨型字黑白高对比」 | `design-demos/roulette-bigtype.html` |
| 现实参照：Wireshark 主窗口三栏联动 | `design-demos/reference-wireshark.html` |
| 最佳设计师：Dieter Rams / Braun 仪器面板 | `design-demos/designer-instrument.html` |

## 用户选择（原话）

> 可以参照串口调试助手 V5.15 野人家园的版本进行设计

追问后的回答：

- 出几版：「直接做一版：沿用 V5.15 的布局和功能分区，在此基础上优化视觉和可读性」
- 前三版要保留的元素：「都不要，纯按 V5.15 来」

## 参照来源

- 野人家园 UartAssist 串口调试助手 V5.15（2025-07-28），https://cmsoft.cn/resource/101.html
- 官方用户手册：https://free.cmsoft.cn/assistcenter/help/UartAssist_UserManual.pdf
  - 主界面：左侧可折叠控制面板（串口设置 / 接收设置 / 发送设置）、数据日志接收窗口、发送框、状态栏收发计数。
  - 工具面板：快捷指令、批量发送、自动应答、历史发送、校验计算器。
  - 主题：白底经典（默认）、黑底经典。

## 约束

- 产品名使用「设备调试工具」，不使用 UartAssist 名称与 logo。
- 单文件 HTML、模拟数据，不接真实串口，不改 `lib/`。
- 产出：`doc/design/serial-console.html`（源文件 `doc/design/src/serial-console.html`）。

---

# 应用图标方向确认

## 展示的三版初稿

| 逻辑 | 方向板 | 截图 |
|---|---|---|
| 秒数轮盘 22 → 信息图 3 号「巨幅剖面手绘（Arranz 式）」，纯 SVG 降级 | `icon-demos/a-cross-section.html` | `icon-demos/a-cross-section.png` |
| 现实参照：Windows Terminal 应用图标与微软 Windows 应用图标规范 | `icon-demos/b-terminal-window.html` | `icon-demos/b-terminal-window.png` |
| 最佳设计师：Dieter Rams / Braun | `icon-demos/c-instrument-dial.html` | `icon-demos/c-instrument-dial.png` |

## 用户选择

在选项「A 接口剖面 / B 波形窗口 / C 仪器旋钮 / 混搭或都不要」中选了 **B 波形窗口**（蓝标题条 + 深色正文里的 UART 波形）。展示时已说明 B 在 16px 需要简化波形。

## 落地

- 源文件：`icon/app_icon.svg`（≥32px）、`icon/app_icon_small.svg`（16、24px，波形简化为单个脉冲）。
- 导出：`icon/export.mjs` → `windows/runner/resources/app_icon.ico` 与 `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png`。
