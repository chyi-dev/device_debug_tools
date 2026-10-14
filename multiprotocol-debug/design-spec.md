# 多协议调试工具 · Design Spec

## 产品

`device_debug_tools`：Flutter 桌面端设备调试工具，从单一串口控制台扩展为 **Serial / BLE / MQTT / WebSocket** 多协议并行调试终端。

## 受众与场景

嵌入式 / IoT 工程师在 Windows / macOS / Linux 上同时对接板卡串口、蓝牙传感器、MQTT 云端与设备 WebSocket，需要统一的收发日志、发送区与连接生命周期管理。

## 核心信息与板块

1. 连接列表：创建 / 切换 / 关闭多连接，协议识别色
2. 统一 Console：时间戳日志、ASCII/HEX、搜索、自动滚动
3. 协议配置侧栏：随选中连接切换（串口参数 / BLE GATT / MQTT Broker·Topic / WS URL）
4. 发送区：编码预览、循环发送（串口能力可逐步复用）
5. 状态栏：当前连接状态、RX/TX、并发数

## 情感基调

冷静、专业、高信息密度；延续现有串口「黑底经典」终端气质，避免霓虹 SaaS 风。

## 输出格式

- HTML 原型：1440×900 桌面视口，单文件可交互
- Flutter：沿用 Cubit + feature 垂直切片，无 get_it

## 视觉母题

「通道」——每条连接是一条可点亮的通信通道；协议色（绿/蓝/橙/紫）作为通道身份，而非装饰。

## Assumptions

- 用户确认交付 HTML 原型后再定方向；Flutter 架构按计划默认 IDE 式（连接列表 + Console）
- 桌面 BLE 能力因平台差异，首版 Gateway 可降级为「平台不支持」提示
- MQTT / WebSocket 使用 Dart 原生或成熟 pub 包
