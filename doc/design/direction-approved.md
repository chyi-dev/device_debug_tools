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

# 工具面板「脚本」页方向确认

## 展示的三版初稿

视觉沿用本稿，只换脚本区骨架；三版共用两个预置脚本、启用开关与运行日志。

| 方向 | 文件 | 截图 |
|---|---|---|
| A · 窄栏内完成：六页签横滑，352px 内列表 + 编辑器 + 运行日志 | `script-demos/panel.html` | `script-demos/panel.png` |
| B · 栏内启停，编辑进浮层：面板只管开关、运行、最近输出；编辑打开加宽对话框，左代码右日志 | `script-demos/dialog.html` | `script-demos/dialog.png`、`script-demos/dialog-edit.png` |
| C · 借中间列：右栏只留列表，编辑器 + 运行日志停靠在数据日志下方 | `script-demos/workspace.html` | `script-demos/workspace.png` |

## 用户选择（原话）

第一次：

> B+脚本应该使用lua，增加数据发送前的钩子，拦截发送数据处理后再发送

调整：

> 以workspace.html为最终版

## 落地

- 布局采用 C（借中间列）；Lua 与发送前拦截沿用第一次的要求。
- 方向稿里的 JS 钩子改为 Lua：`on_receive(frame)`、`before_send(frame)`；`before_send` 返回处理后的帧再发出，返回 `nil` 则拦截不发。
- 钩子放进 `src/engine.js` 的发送入口，发送按钮、快捷指令、批量、自动应答都经过。
- 规则写入 `design.md` 工具面板一节。

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

---

# 脚本页「Lua 教程」方向确认

## 展示的三版初稿

六课内容相同（钩子、打印、认帧头、补校验、拦截、Modbus CRC），只换教程的位置与操作。源文件 `tutorial-demos/src/`，`tutorial-demos/build.mjs` 生成，`tutorial-demos/shoot.mjs` 截图。

| 方向 | 文件 | 截图 |
|---|---|---|
| A · 课表：脚本页顶部切「我的脚本 / 教程」，点课展开，「用这课新建脚本」「样例试跑」 | `tutorial-demos/list.html` | `tutorial-demos/list.png` |
| B · 课本：停靠区运行日志旁加「教程」，一页一课，可插入编辑器 | `tutorial-demos/book.html` | `tutorial-demos/book.png` |
| C · 选题新建：「新建」选课卡片；右栏说明换成可插入的片段 | `tutorial-demos/pick.html` | `tutorial-demos/pick.png`、`tutorial-demos/pick-new.png` |

## 用户选择

在「A 课表 / B 课本 / C 选题新建 / B+C 混搭」中选了 **A 课表**。

## 落地

- 课表并入主稿脚本页；样例试跑把该课样例帧交给脚本引擎，不往串口写。
- 规则写入 `design.md` 工具面板一节。

---

# 自动应答「规则教程」方向确认

## 展示的三版初稿

七课内容相同（模板四课、正则三课），只换教程在规则对话框右侧的展开方式。源文件 `reply-tutorial-demos/src/`，`reply-tutorial-demos/build.mjs` 生成，`reply-tutorial-demos/shoot.mjs` 截图。

| 方向 | 文件 | 截图 |
|---|---|---|
| A · 课表：右侧列表点一课就地展开说明、字节格和将发出的 HEX，可填入左边表单 | `reply-tutorial-demos/list.html` | `reply-tutorial-demos/list.png` |
| B · 分步：课名索引加三步（看收到、写入匹配、写入应答） | `reply-tutorial-demos/steps.html` | `reply-tutorial-demos/steps.png` |
| C · 对照：课名索引加固定的收到 / 将发出对照条 | `reply-tutorial-demos/trace.html` | `reply-tutorial-demos/trace.png` |

## 用户选择

> 按照A · 课表实现

## 落地

- 新增 / 编辑应答规则对话框左右分栏：左表单、右课表。课在 `lib/features/serial/model/reply_lessons.dart`，文案走 slang `serial.reply.lessons.<key>`。
- 「填入编辑器」只写表单，不保存。设计稿由 `src/reply-tutor.js` 在打开规则对话框时挂上同一课表。
- 规则写入 `design.md` 工具面板「自动应答」一行。

---

# 配置导入导出方向确认

## 展示的三版初稿

范围由用户先选定：只打包快捷指令、自动应答、批量发送、脚本四类。三版数据规则相同（整表替换、文件里没有的类别不动、旧单列表文件可读、命中次数归零、启用脚本与运行中批量给提醒），只换入口与确认方式。源文件 `config-demos/src/`，`config-demos/build.mjs` 生成，`config-demos/shoot.mjs` 走流程并截图。

| 方向 | 文件 | 截图 |
|---|---|---|
| A · 清单：文件菜单收成「导出配置… / 导入配置…」，两边都是四行勾选清单，写清文件条数与当前条数 | `config-demos/checklist.html` | `config-demos/checklist.png`、`config-demos/checklist-export.png` |
| B · 总包：保留分项导入导出，另加「导出全部 / 导入全部」，导入用当前 / 导入后对照表整体确认 | `config-demos/bundle.html` | `config-demos/bundle.png` |
| C · 页签：四个页签标题条各自导出 / 导入，菜单为整包清单（展示时已说明 352px 栏内拥挤） | `config-demos/tab.html` | `config-demos/tab.png`、`config-demos/tab-bar.png` |

## 用户选择（原话）

> 版 A · 清单

## 落地

- 主稿文件菜单去掉原来的「导出 / 导入快捷指令」「导出 / 导入应答规则」，换成「导出配置… / 导入配置…」；清单与替换逻辑并入 `src/serial-console.html`。
- 规则写入 `design.md`「配置导入导出」一节。

---

# 操作折叠方向确认

## 展示的三版初稿

快捷指令、批量发送、自动应答、脚本都先加上「复制」，溢出是真的，再用三种骨架收掉多余按钮。历史记录仍是「填入 / 删除」，三版都不折叠。颜色、字号和模拟数据沿用主稿；菜单和操作条用现有 `panel` / `line` / `text` / `off`。源文件 `action-demos/src/`，`action-demos/build.mjs` 注入主稿生成，`action-demos/shoot.mjs` 以 1440×900 截图。本机没有 Edge，截图用 Chrome（`PW_CHANNEL=chrome`）。

| 方向 | 文件 | 截图 |
|---|---|---|
| A · 行尾「更多」：快捷指令留「发送」「编辑」，文件夹留「新增」，批量顶栏留「新建」「编辑」，自动应答留「执行」「编辑」，脚本标题栏留「运行」「收起」。复制、删除进下拉，删除用危险色，点下去仍是确认框 | `action-demos/more.html` | `action-demos/more-quick.png`、`action-demos/more-menu.png`、`action-demos/more-batch.png`、`action-demos/more-reply.png`、`action-demos/more-script.png` |
| B · 选中才展开：未选中的行只有主操作。点中一行后，下方多出操作条，放编辑、复制、删除。批量顶栏只留下拉和「新建」，编辑、复制、删除跟到步骤列表上方 | `action-demos/select.html` | `action-demos/select-quick.png`、`action-demos/select-open.png`、`action-demos/select-batch.png`、`action-demos/select-reply.png`、`action-demos/select-script.png` |
| C · 右键菜单：行上只留主操作（发送、执行、运行、文件夹的「新增」、批量的「新建」「编辑」）。编辑、复制、删除右键该行弹出 | `action-demos/context.html` | `action-demos/context-quick.png`、`action-demos/context-menu.png`、`action-demos/context-batch.png`、`action-demos/context-reply.png`、`action-demos/context-script.png` |

## 用户选择（原话）

> 按C · 右键菜单 方案执行，先归档到主设计稿中，再实现代码

## 落地

- 主稿并入右键菜单与「复制」：行上只留主操作（发送、执行、运行、文件夹的「新增」、批量的「新建」「编辑」），编辑、复制、删除右键该行弹出；删除仍走确认框。
- 复制规则沿用设计稿演示版：立即克隆、命名加「副本」、快捷指令不占 F 键、应答与脚本克隆默认停用、插入到源条目之后。
- 规则写入 `design.md` 工具面板一节。
- Flutter 已按此实现：右键菜单控件 `SerialContextMenu` 在 `lib/features/serial/widget/serial_chrome.dart`，复制逻辑 `duplicateQuick/Batch/Rule/Script` 在 `lib/features/serial/cubit/serial_console_cubit.dart`，提示走 `serial.notice.duplicated`。
- 后续调整（用户原话「下拉控件应该居左占据横向所有剩余空间，同时增加对应选择的删除功能」）：批量顶栏任务下拉居左占满剩余宽度，「删除」按钮恢复到顶栏（删当前选中任务，仍走确认框）；右键菜单保持「复制 / 删除」。
