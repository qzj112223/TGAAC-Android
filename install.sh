#!/bin/sh
# macOS / Linux：把 APK 和数据包装到已连接的 Android 设备上
set -e
PKG=org.nx2a.t0100d7f00faaa000
APK=TheGreatAceAttorneyChronicles.apk
DATA=TheGreatAceAttorneyChronicles-data

command -v adb >/dev/null || { echo "[!] 没找到 adb（platform-tools 需要加进 PATH）"; exit 1; }
[ -f "$APK" ] || { echo "[!] 缺少 $APK"; exit 1; }
[ -d "$DATA" ] || { echo "[!] 缺少数据包目录 $DATA（从 port-out 拷过来）"; exit 1; }

echo "[1/5] 检查设备..."
adb devices
echo "    没有 device 的话，先插 USB 并打开「USB 调试」。"

echo "[2/5] 安装 APK..."
adb install -r "$APK" || { echo "[!] 安装失败：签名冲突就先卸载旧版本"; exit 1; }

echo "[3/5] 建立数据目录..."
adb shell mkdir -p "/sdcard/Android/data/$PKG/files"

echo "[4/5] 推送游戏数据（约 4 GB，第一次要几分钟）..."
adb push "$DATA/." "/sdcard/Android/data/$PKG/files/"

echo "[5/5] 启动..."
adb shell am start -n "$PKG/android.app.NativeActivity" >/dev/null || true

echo "完成。首次启动若提示存储权限，允许即可。"
