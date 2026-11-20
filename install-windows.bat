@echo off
setlocal
chcp 65001 >nul
set PKG=org.nx2a.t0100d7f00faaa000
set APK=TheGreatAceAttorneyChronicles.apk
set DATA=TheGreatAceAttorneyChronicles-data

where adb >nul 2>nul
if errorlevel 1 (
  echo [!] 没找到 adb（请把 platform-tools 加进 PATH，或用 DeskBox 自带的 adb.exe）
  pause & exit /b 1
)

if not exist "%APK%" ( echo [!] 缺少 %APK% & pause & exit /b 1 )
if not exist "%DATA%" ( echo [!] 缺少数据包目录 %DATA%（把 port-out 里那个同名目录拷过来） & pause & exit /b 1 )

echo [1/5] 检查设备...
adb devices
echo    如果上面没有 device，请先插 USB 并打开「USB 调试」。

echo [2/5] 安装 APK...
adb install -r "%APK%" || ( echo [!] 安装失败：如果提示签名冲突，先卸载旧版本再试 & pause & exit /b 1 )

echo [3/5] 建立数据目录...
adb shell mkdir -p /sdcard/Android/data/%PKG%/files

echo [4/5] 推送游戏数据（约 4 GB，第一次要几分钟）...
adb push "%DATA%\\." /sdcard/Android/data/%PKG%/files/

echo [5/5] 启动...
adb shell monkey -p %PKG% -c android.intent.category.LAUNCHER 1 >nul 2>nul
adb shell am start -n %PKG%/android.app.NativeActivity >nul 2>nul

echo.
echo 完成。首次启动若提示存储权限，允许即可。
pause
