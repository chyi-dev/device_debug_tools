/// Windows 下是否把勾选状态写入 DCB 线路控制。
///
/// - `true`：写入 ON（ENABLE）
/// - `false`：写入 OFF（DISABLE）
/// - `null`：不写该字段（保持 -1），避免 Windows 上 `*_CONTROL_DISABLE` 触发 SetCommState 失败
bool? serialLineControlValue({required bool on, required bool isWindows}) {
  if (on) return true;
  if (isWindows) return null;
  return false;
}
