# device_debug_tools

Flutter 桌面端串口调试台，支持 **Windows / macOS / Linux**。打开串口后可收发数据，并用快捷指令、批量发送、自动应答和 Lua 脚本处理重复操作。

- [项目介绍](doc/项目介绍.md)：能力、数据流、工作区与平台差异
- [使用教程](doc/使用教程.md)：连端口、收发、应答规则和脚本
- [设计说明](doc/design/design.md)：界面尺寸、颜色与交互，改 UI 时以它为准

技术上采用 feature-first 垂直切片、Cubit 状态管理、go_router 路由，以及 Hive 本地存储。

## 技术栈

| 类别 | 选型 |
|------|------|
| 框架 | Flutter 3.10+（Dart `^3.10.8`） |
| 状态 | flutter_bloc（仅 Cubit） |
| 路由 | go_router（`StatefulShellRoute`；当前只有串口一页，不显示侧边导航） |
| 国际化 | slang（zh / en） |
| 本地存储 | Hive |
| 日志 | logger + 文件落盘（`AppLogger`） |
| 加载提示 | flutter_easyloading |
| 串口 | Windows 用 Win32；macOS / Linux 用 `flutter_libserialport` |
| 脚本 | `lua_dardo_plus` |

## 项目结构

```
lib/
├── app/          # 启动、路由、主题、全局 Cubit、DI
├── core/         # 存储、日志、响应式、通用 Widget、工具
├── features/
│   ├── serial/   # 串口调试台（当前产品）
│   └── home/     # 旧占位页，未挂到路由
├── shared/       # 跨模块模型与扩展
├── i18n/         # 多语言文案与生成代码
├── env/          # 环境标志 appIsDev
├── main.dart     # 生产入口
└── main_dev.dart # 开发入口
doc/
├── 项目介绍.md
├── 使用教程.md
└── design/       # 界面设计稿与设计说明
```

## 快速开始

```bash
flutter pub get
flutter run -d windows                       # 生产入口 main.dart
flutter run -d windows -t lib/main_dev.dart  # 开发入口（debug 日志 + 文件日志）
```

将 `windows` 换成 `macos` 或 `linux` 即可在对应系统上运行。

> Windows 上使用插件需开启“开发者模式”（设置 → 系统 → 开发者选项），否则 `flutter pub get` 会提示需要 symlink 支持。

### 环境与数据目录

| 维度 | 说明 |
|------|------|
| 开发环境 | `-t lib/main_dev.dart` → `appIsDev=true`，控制台 debug 级日志 + 文件日志 |
| 生产环境 | `main.dart` → `appIsDev=false`，仅 warning 以上日志 |
| 数据目录 | 系统 Application Support 目录（`getApplicationSupportDirectory()`），其下 `hive/` 存偏好与串口工作区、`logs/` 存应用日志 |

日志文件按天生成（`app_yyyy_MM_dd.log`），默认保留 7 天，单文件超过 10MB 时轮转，配置见 `lib/core/constants/app_constants.dart`。串口收发内容不写入该目录，保存方式见 [使用教程](doc/使用教程.md)。

## 常用命令

```bash
# 国际化生成（修改 lib/i18n/*.i18n.json 后）
dart run slang

# 静态分析
flutter analyze

# 测试
flutter test
```

## 打包发布

| 平台 | 环境要求 | 命令 | 产物 |
|------|----------|------|------|
| Windows | Windows + Visual Studio（C++ 桌面开发） | `flutter build windows --release` | `build/windows/x64/runner/Release/` |
| macOS | macOS + Xcode | `flutter build macos --release` | `build/macos/Build/Products/Release/` |
| Linux | GTK3、CMake、Ninja、Clang、pkg-config | `flutter build linux --release` | `build/linux/x64/release/bundle/` |

- 每个平台只能在对应系统上构建。
- Windows 的 `device_debug_tools.exe` 依赖同目录的 `flutter_windows.dll`、插件 dll 与 `data/`，分发时须带上整个 `Release` 目录，单独拷贝 exe 会报“找不到 flutter_windows.dll”。

### Windows 安装包（Inno Setup）

需先安装 [Inno Setup 6](https://jrsoftware.org/isdl.php)，并确保 `ISCC.exe` 在 PATH 中。在项目根目录执行：

```bash
flutter build windows --release
iscc installer/windows/device_debug_tools.iss
```

产物：`build/installer/device_debug_tools-<version>-setup.exe`。脚本中的 `MyAppVersion` 需与 `pubspec.yaml` 的版本同步。目标机缺少 `VCRUNTIME140.dll` 时，需安装 Microsoft Visual C++ 2015–2022 可再发行组件（x64）。

- macOS 访问串口、USB、网络或文件时，需要在 `macos/Runner/*.entitlements` 中声明对应权限。

### 发布检查清单

- [ ] 正式包走 `main.dart`（`appIsDev=false`）
- [ ] `flutter analyze` 无问题，`flutter test` 通过
- [ ] `pubspec.yaml` 的 `version: x.y.z+build` 已更新，并同步 `installer/windows/device_debug_tools.iss` 的 `MyAppVersion`

## 架构要点

- **启动**：`main.dart` / `main_dev.dart` → `bootstrap()`，依次初始化 Hive、日志、语言、EasyLoading，再由 `buildAppRoot` 组装 Provider 树
- **DI**：`AppDependencies` 注册全局 Repository / Service；页面内用 `BlocProvider` 创建 Cubit。串口实现在这里按平台选择：Windows 为 `Win32SerialGateway`，其他为 `LibserialportGateway`
- **路由**：路径常量集中在 `lib/app/router/route_names.dart`；新增导航项需同步修改 `app_router.dart` 的 branch 和 `MainShell` 的 destinations。当前初始路由是 `/serial`
- **全局状态**：`AppCubit` 管理主题与语言，并持久化到 `UserPrefsStorage`。串口工作区由 `SerialWorkspaceStore` 写入同一个 settings box
- **布局**：桌面端使用逻辑 px + `AppSpacing`，按 `AppDesign` 的窗口断点适配，不使用 ScreenUtil。调试台尺寸见 `lib/features/serial/serial_metrics.dart`

## Cursor Rules

AI 辅助开发约定位于 [`.cursor/rules/`](.cursor/rules/)：

| 文件 | 说明 |
|------|------|
| `project.mdc` | 全局约定（始终生效） |
| `app.mdc` | 应用壳层与路由 |
| `core.mdc` | 基础设施层 |
| `feature.mdc` | Feature 开发规范 |
| `serial-console.mdc` | 串口调试台界面与行为 |
| `i18n.mdc` | 国际化规范 |
| `shared.mdc` | 共享模型 |
| `responsive.mdc` | 桌面端布局（间距/字号 token、窗口断点） |
| `platform.mdc` | 三端构建与发布 |

## 模块说明

| Feature | 说明 |
|---------|------|
| serial | 串口调试台。页面、Cubit、工具面板、Lua 引擎与工作区都在 `lib/features/serial/` |
| home | 旧占位页，未注册到路由 |
