# 品牌规范 · 设备调试工具

## 现状

- 产品名：设备调试工具（工程名 `device_debug_tools`）。
- 应用图标：方向 B「波形窗口」（见 `direction-approved.md`）。源稿 `icon/app_icon.svg`（≥32px）、`icon/app_icon_small.svg`（16/24px）；导出脚本 `icon/export.mjs`。
- 部署路径：`windows/runner/resources/app_icon.ico`；`macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png`。
- 无外部品牌资产可取，图标从产品本身（串口调试）推导，不借用第三方标记。

## 禁区

- 不使用 UartAssist / 野人家园的名称、logo 或图标轮廓。
- 不用渐变、发光、emoji、左侧色条（同 `design.md`）。
- 图标内不放文字：中文品名在 16px 不可读。

## 色值

全部引用 [`design.md`](design.md) 的 token，不另造颜色：

| token | 白底经典 | 黑底经典 |
|---|---|---|
| `accent` | `#1769c2` | `#4c9bf0` |
| `win` | `#e9edf1` | `#16191d` |
| `panel` | `#f7f8fa` | `#1f2329` |
| `on`（端口已打开） | `#1f9d55` | `#3ccf7a` |
| `log-sys` | `#9a5a00` | `#e5b54a` |

绿色只表达「端口已打开」，图标里出现时也保持这个含义。

## 图标尺寸

- Windows：`app_icon.ico` 内含 16、24、32、48、64、128、256。
- macOS：`app_icon_16.png` 至 `app_icon_1024.png`（见 `Contents.json`）。
- 先保证 16px 轮廓可辨，再细化大尺寸。
