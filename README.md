# The Great Ace Attorney Chronicles 1&2 — Android 原生移植（构建产物）

这个仓库只放**构建好的 APK 和安装脚本**。不含任何游戏文件、密钥或反编译产物。

## 下载

在 [Releases](../../releases) 里下最新的 `TheGreatAceAttorneyChronicles.apk`。

## 需要什么

- Android 9+，arm64，**Adreno GPU**（骁龙 6xx/7xx/8xx）——APK 内置了给 Adreno 的 Turnip 驱动
- 约 4 GB 空闲空间、4 GB 内存
- **游戏数据包**（约 4.0 GB）不在这个仓库里：它由 `nx2android` 的 porter 从**你自己的卡带 dump** 生成：

```bash
git clone https://github.com/shirai91/nx2android.git
cd nx2android
py -m porter port <你的游戏文件夹> -o out --vulkan-driver <turnip.so>
```

## 安装

1. 装 APK
2. 把数据包里的全部内容推到 `/sdcard/Android/data/org.nx2a.t0100d7f00faaa000/files/`
   （`RomFS/`、`env.txt`、`shaders.dmsv` … 直接在 `files/` 下）
3. 启动；首次要存储权限

Windows 用 `install-windows.bat`，macOS/Linux 用 `install.sh`（需要 adb，且数据包目录放在同目录）。

## 已知情况

- 游戏引擎原生 30 fps（GPU 只占 10–14 ms，余量很大，但帧闸门在引擎里）
- 覆盖菜单、存档导出导入、底座模式触控都可用
- 只在自己 dump 的卡带上测试过，不提供游戏本体

## 版权

游戏与角色资源版权归 CAPCOM。这个仓库只分发移植层代码的构建产物。