# AGENTS.md — 从自己的 XCI / NSP 生成游戏数据包

> 复制这一整篇给 coding agent。任务：用 [nx2Android](https://github.com/shirai91/nx2android) 的 `porter`，从**用户自己 dump 的游戏**生成这个移植需要的数据包（和能直接导入的 ZIP），并在设备上验证到「能进游戏、贴图正常」。

---

## 目标产物

| 产物 | 说明 |
|---|---|
| `<Game>-data/` | 数据目录：**3.97 GiB / 约 5,200 文件**（RomFS、mods、env.txt、空 saves） |
| `<Game>-data.zip` | **store 模式**（不压缩），给应用内导入用 |
| `<Game>.apk` | 可选：27.7 MB，**内含 Turnip 驱动** |
| 验证记录 | 启动日志关键行 + 至少一张游戏内截图 |

## 输入（必须由用户提供，agent 不得自行寻找或下载）

1. **游戏本体**：XCI 或 NSP —— 用户从自己的主机 dump
2. **`prod.keys`** —— 用户从自己的主机 dump（`Lockpick_RCM` 之类）
3. 放游戏的目录（含 `.xci` 或 `.nsp`，更新/DLC 可一并放在同目录）
4. 环境：**Python 3.11+**、**Android NDK**（porter 自动找）、**JDK**（`d8` 需要）

> 拿不到 1/2 就停下来问，不要用网上找的 keys 或游戏文件。

## 步骤（全部实测过）

### 1. 取工具

```bash
git clone https://github.com/shirai91/nx2android.git      # 握手失败就多重试几次
cd nx2android
py -m pip install -r requirements.txt
```

### 2. 先看能不能识别

```bash
py -m porter inspect /path/to/game-folder
```

未支持的游戏会打印 `no game profile for <TITLE_ID>` 并以**退出码 1** 结束——这是正常的，不是崩溃，下一步加 `--experimental` 即可。

### 3. 生成（**必须带 `--vulkan-driver`**）

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'; $env:PATH="$env:JAVA_HOME\bin;$env:PATH"
py -m porter port /path/to/game-folder -o out -k /path/to/prod.keys --experimental `
    --vulkan-driver path/to/vulkan.ad07xx.so --progress lines
```

- **不带 `--vulkan-driver`**：APK 只有 3.96 MB、没有内置驱动。原厂 Adreno 实测 `Vulkan 1.1.128`，启动即 `FATAL [vk] the device has neither dynamic rendering nor imageless ...` 退出
- 驱动从哪来：本仓库 Release 的 APK 里解出 `lib/arm64-v8a/libsysmem_vulkan.ad07xx.so`（16.36 MB）
- 忘了设 `JAVA_HOME` → `d8.bat exit code 1 / JAVA_HOME is not set`

### 4. 补两个贴图 key（第一次生成后**必做**）

第一次 `porter port` 会在 `<游戏目录>/<TITLE_ID>_build/profile/<TITLE_ID>/game.tsv` 生成一份 survey 出来的 profile，往里面加两行：

```
tex_flush_upload	on
tex_dirty_upload	on
```

再跑一次同样的命令（会复用这份 profile，日志里能看到 `reusing the provisional profile`）。

不补的后果：这个游戏把贴图拷进 CPU 缓存池后从不刷 cache → **3D 人物和道具全黑**（背景和 UI 正常，很容易以为是驱动问题）。

### 5. 打成 ZIP（给应用内导入）

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
  "out/<Game>-data", "out/<Game>-data.zip",
  [System.IO.Compression.CompressionLevel]::NoCompression, $true)
```

- 必须 **store**：RomFS 里的资源本来就压过了，Deflate 只是白烧 CPU（实测 store 解压 4.27 GB 只要 **22 秒**）
- 顶层目录保持 `<Game>-data/`，应用内导入会自动剥掉这一层

## 验收（逐条对比）

| 检查 | 通过标准 |
|---|---|
| 数据目录 | 3.97 GiB（4.27 GB）/ 约 5,200 个文件 |
| APK | 27.7 MB，含 `lib/arm64-v8a/libsysmem_vulkan.ad07xx.so`（16.36 MB） |
| 安装 | `adb install -r` 成功，图标名正确 |
| 启动 | 首次弹免费使用声明 → 检测到数据 → 自动进游戏 |
| 驱动 | 日志 `[vk] GPU Turnip Adreno ... Vulkan 1.3.x, driver 25.99.99` |
| 错误 | 日志里 `[RED]` 计数为 **0** |
| 画面 | 进第一章 3D 场景，人物/道具**不发黑** |
| 帧率 | 覆盖层稳定 **30.0 fps**（引擎固定 1/30，属预期） |
| 导入 | 应用内选这个 ZIP → 解压完成 → 进游戏 |

日志路径：`/sdcard/Android/data/<包名>/files/log.txt`

## 红线

1. 不许下载或使用别人的 `prod.keys`、游戏 dump、预打包数据包
2. 不许把游戏数据、keys、XCI/NSP 提交进任何 git 仓库
3. 报告里可以写路径和命令，**keys 一律不写**
4. 数据包内容不对就重跑，不要手改 RomFS 里的文件

## 常见失败与判断

| 现象 | 原因 |
|---|---|
| `d8.bat exit code 1` + `JAVA_HOME is not set` | 没设 `JAVA_HOME`（指 JBR） |
| `inspect` 退出码 1 | 未支持的游戏，正常 |
| 数据目录只有几 MB | keys 不对或目录里没有本体，RomFS 没解出来 |
| APK 3.96 MB | 漏了 `--vulkan-driver` |
| 3D 人物/道具发黑 | 漏了那两个贴图 key |
| 只有 2 fps | 用的是上游未修版本（内存池 256 MB），需 PR #477 的修复 |
| `git clone` 握手失败 | 网络/代理，重试 |
| 存档读不到 | 数据包要来自**同一版本**的游戏（本体版本别混用） |
