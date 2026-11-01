#!/usr/bin/env bash
# macOS 安装镜像脚本
# 先执行 flutter build macos --release，再在项目根目录执行：
#   installer/macos/make_dmg.sh
# 版本号从 pubspec.yaml 的 version 读取（+ 前面的部分）。
# 当前为临时签名，不公证。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

VERSION="$(awk '/^version:/{print $2; exit}' pubspec.yaml | cut -d+ -f1)"
if [[ -z "${VERSION}" ]]; then
  echo "无法从 pubspec.yaml 读取 version" >&2
  exit 1
fi

APP_NAME="device_debug_tools"
APP="build/macos/Build/Products/Release/${APP_NAME}.app"
BINARY="${APP}/Contents/MacOS/${APP_NAME}"
OUT_DIR="build/installer"
DMG="${OUT_DIR}/${APP_NAME}-${VERSION}-macos.dmg"

if [[ ! -d "${APP}" ]]; then
  echo "未找到 ${APP}，请先执行 flutter build macos --release" >&2
  exit 1
fi

ARCHS="$(lipo -info "${BINARY}")"
if [[ "${ARCHS}" != *arm64* || "${ARCHS}" != *x86_64* ]]; then
  echo "不是通用二进制（需要同时包含 arm64 与 x86_64）：${ARCHS}" >&2
  exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
mkdir -p "${OUT_DIR}"
cp -R "${APP}" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"
hdiutil create \
  -volname "设备调试工具" \
  -srcfolder "${STAGE}" \
  -ov -format UDZO \
  "${DMG}"

echo "已生成 ${DMG}"
