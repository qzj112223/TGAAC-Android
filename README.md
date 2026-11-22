# The Great Ace Attorney Chronicles 1&2 — Android 原生移植

> 🎉 **感谢 [nx2Android](https://github.com/shirai91/nx2android)** —— 本移植完全由它的 `porter` 工具链生成，没有它就没有这个项目。
> 上游把 Switch 游戏的 ARM64 代码翻译成 C、补上 Horizon 系统服务与 Maxwell GPU 的兼容层，并把整套工具链开源（MIT），
> 让「自己 dump、自己生成、自己玩」成为可能。感谢作者与所有贡献者：**<https://github.com/shirai91/nx2android>**

> 本项目是从自己 dump 的 Switch 卡带生成的 **原生移植**：不是模拟器，游戏逻辑直接在本机跑，渲染走 Vulkan。

> **最新版：[v1.2.0](../../releases/tag/v1.2.0)** —— 理论上兼容天玑/Mali 设备（**只实测了荣耀 Play5 活力版，天玑 900，30 fps**）：修复 MediaTek 多 fd 句柄让零拷贝失效、Mali 的 CPU 缓存一致性、present 缺屏障导致的闪烁；同时修复章节标题卡片黑屏与过场视频的 AVC 参数集丢失。

**本仓库只包含构建好的 APK 和脚本，不包含任何游戏数据、密钥或反编译产物。**

---

## ⚠️ 免责声明 / Disclaimer

<details open>
<summary>中文</summary>

1. 本移植版**完全免费**，仅供**学习与技术研究**使用。
2. **严禁**销售、收费分发、捆绑收费、以任何形式导流变现，或用于其他盈利活动。
3. 本仓库**不提供**游戏本体、RomFS、密钥（`prod.keys` / `title.keys`）、NSP/XCI 或任何从游戏中提取的资源。
4. 游戏及其角色、音乐、剧本等全部内容的著作权归 **CAPCOM** 及原权利人所有。
5. 使用者必须**自行购买**游戏并从自己的主机 dump 数据；因使用本仓库内容产生的一切后果由使用者自负。
6. 若权利人认为本仓库有不妥之处，请通过 Issue 联系，我会立即处理（移除/下架）。

</details>

<details>
<summary>English</summary>

1. This port is **free of charge** and is meant for **study and technical research only**.
2. **Selling** it, charging for it, bundling it with a paid service, or any other commercial use is **prohibited**.
3. This repository contains **no game data**: no RomFS, no keys, no NSP/XCI, no extracted assets.
4. All game content belongs to **CAPCOM** and its rights holders.
5. You must **own the game** and dump it from your own console. Any consequences of use are yours alone.
6. Rights holders may open an Issue and the repository will be taken down on request.

</details>

---

## 这是什么

- Switch 版《大逆转裁判 1&2 成步堂龙之介的冒险与觉悟》的 **Android 原生重编译版本**：把游戏的 ARM64 代码翻译成 C 再编译成原生程序，运行时提供 Horizon 系统服务与 Maxwell GPU 的兼容层
- 用 [nx2Android](https://github.com/shirai91/nx2android)（`porter` 工具链）生成，渲染走 **Vulkan**（Adreno 设备内置 Turnip 驱动）
- 自带屏幕手柄、覆盖菜单（帧率/透明度/布局编辑/震动/底座模式/导出导入存档）、底座模式触控

## 环境要求

| 项 | 要求 |
|---|---|
| 系统 | **Android 10+**（minSdk 29，targetSdk 36），arm64-v8a |
| GPU | **Adreno**。内置 Turnip 只支持 Adreno（本机实测 Adreno 650；Mali / PowerVR 用不了） |
| 存储 | 数据包 **3.97 GiB / 4.27 GB**（约 5,200 个文件）；应用内导入时 ZIP 本身也在机内，合计需 **约 8.6 GB** 空闲 |
| 内存 | 建议 6 GB 以上（实测游戏堆 3.14 GB、堆区 3.25 GB） |
| root | **不需要**（驱动随 APK，应用内加载） |

> 上表与后文的时间、性能数字，除标注「估算」外，都在 OPPO Pad（OPD2101 / 骁龙 870 / Adreno 650 / Android 15）上实测。


## 安装

### 1. 装 APK

从 [Releases](../../releases) 下载 `TheGreatAceAttorneyChronicles.apk` 安装。

> APK 用自签名证书，若之前装过别的签名版本，先卸载再装。

### 2. 放进游戏数据

**方式 A：应用内导入（推荐，不需要电脑）**

1. 首次启动会弹出**免费使用声明**，选择「知悉并继续」
2. 检测不到数据时会显示「**选择游戏数据 ZIP**」
3. 用系统文件选择器挑一个数据包 ZIP（见下方「自己生成数据包」）
4. 应用自动解压到 `/sdcard/Android/data/org.nx2a.t0100d7f00faaa000/files/`，完成后自动进游戏
   - 实测 4,268,285,912 字节 / 约 5,200 个文件 **22 秒**解完（OPPO Pad，UFS），过程中显示文件数与 MB 数

> **不需要任何存储权限**：数据放在应用自己的 `Android/data/<包名>/files` 里，应用内导入走系统文件选择器。
> 实测：`MANAGE_EXTERNAL_STORAGE` 和 `READ_EXTERNAL_STORAGE` **都没有授予**，游戏照常启动、4.27 GB 的包照常导入。
> 只有把 RomFS 放在公共目录（`porter install --romfs-at /sdcard/...`）时才需要「所有文件访问」，那一步 porter 会自己授予。

**方式 B：adb 推送（快）**

```bash
adb push TheGreatAceAttorneyChronicles-data/. /sdcard/Android/data/org.nx2a.t0100d7f00faaa000/files/
```

也可以直接用 porter 一步到位（会顺带装 APK）：

```bash
py -m porter install TheGreatAceAttorneyChronicles-data --device <序列号>
```

## 自己生成数据包（本仓库不提供）

数据包必须由你**自己的** XCI / NSP dump 生成，工具是 [nx2Android](https://github.com/shirai91/nx2android)。

### 准备

1. **游戏本体**：XCI 或 NSP（你从自己主机 dump 的；`NSP` 目录里也可以放更新和 DLC）
2. **密钥**：`prod.keys`（用 `Lockpick_RCM` 之类从自己的主机 dump；**不要**从网上下载别人的）
3. **Python 3.11+**
4. **Android NDK**（porter 自动找，缺失时会提示路径）。本流程在 **Windows 11 上实测**过；macOS / Linux 未实测

### 步骤

```bash
# 1) 取工具
git clone https://github.com/shirai91/nx2android.git    # 网络不稳就多重试几次
cd nx2android
py -m pip install -r requirements.txt

# 2) 先看这堆文件能不能被识别（可选）
py -m porter inspect /path/to/game-folder
#    未支持的游戏会打印 "no game profile ..." 并以退出码 1 结束，这是正常的，不是崩溃

# 3) 生成 APK 和数据包
py -m porter port /path/to/game-folder \
    -o out \
    -k /path/to/prod.keys \
    --experimental \
    --vulkan-driver /path/to/vulkan.ad07xx.so     # ← 强烈建议带上，见下方说明
```

跑完会得到：

```
out/TheGreatAceAttorneyChronicles.apk
out/TheGreatAceAttorneyChronicles-data/      ← 3.97 GiB（4.27 GB），约 5,200 个文件
```

### 构建时的三个坑（实测过）

**① 不带 `--vulkan-driver` 的 APK 只有 4 MB，它没有内置驱动**

那样只能吃系统驱动。原厂驱动在这台机器上实测是 `Adreno (TM) 650, Vulkan 1.1.128, driver 512.502.0`，
启动即 `FATAL [vk] the device has neither dynamic rendering nor imageless ...` 并退出——移植按 Vulkan 1.3 选设备（源码里 `apiVersion >= VK_API_VERSION_1_3`）。
所以要么刷系统级 Turnip，要么把驱动打进 APK（下面这条）。
Turnip 驱动可以从 **本仓库 Release 的 APK 里取**：

```bash
# 从已发布的 APK 里解出驱动（16.4 MB）
unzip -o TheGreatAceAttorneyChronicles.apk 'lib/arm64-v8a/libsysmem_vulkan.ad07xx.so' -d turnip
py -m porter port /path/to/game-folder -o out -k prod.keys --experimental \
    --vulkan-driver turnip/lib/arm64-v8a/libsysmem_vulkan.ad07xx.so
```

带驱动后 APK 27.7 MB，装上即可运行（驱动在应用内加载，不需要 root）。

**② 自己 survey 出来的 profile 缺两个贴图 key，3D 人物/道具会发黑**

这个游戏把贴图拷进 CPU 缓存池后从不刷 cache。第一次 `porter port` 会在
`<游戏目录>/<TITLE_ID>_build/profile/<TITLE_ID>/game.tsv` 生成一份 survey 出来的 profile，
在其中补两行再跑一次：

```
tex_flush_upload	on
tex_dirty_upload	on
```

（这两行已经在 [PR #476](https://github.com/shirai91/nx2android/pull/476) 里提给上游；合并后就不用管了。）

**③ 上游 HEAD 还没有本次的移植层修复**

本仓库的 APK 是在上游基础上带了 [PR #477](https://github.com/shirai91/nx2android/pull/477) 的修复的
（内存池 256→254 MB、覆盖菜单重绘、fence 等待上限、底座模式触控）。
直接从上游 clone 构建出来的是未修复版本：在这类机器上会掉到 2 fps、覆盖菜单会顿卡。
想拿到同样的效果，就等 PR 合并，或者把那 8 个文件的改动自己打上去。

### 打成 ZIP（给应用内导入用）

```powershell
# Windows PowerShell
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
  "out/TheGreatAceAttorneyChronicles-data",
  "out/TheGreatAceAttorneyChronicles-data.zip",
  [System.IO.Compression.CompressionLevel]::NoCompression, $true)
```

```bash
# macOS / Linux（zip 的 -0 = store；这条命令未在 Linux 上实测，PowerShell 那条已实测）
cd out && zip -0 -r TheGreatAceAttorneyChronicles-data.zip TheGreatAceAttorneyChronicles-data
```

- 用 **不压缩（store）**：RomFS 里的资源本来就压过了，Deflate 只是白烧 CPU
- ZIP 顶层可以是 `TheGreatAceAttorneyChronicles-data/` 这一层目录，应用会自动剥掉

## 操作

- 顶部 **☰** 呼出覆盖菜单：显示手柄 / 透明度 / 编辑布局 / 震动 / 显示帧率 / 模式（掌机 ↔ 底座）/ 导出存档 / 导入存档 / 按键布局 / 音频输出 / 触屏操作 / 继续游戏
- 「触屏操作」打开后，手指直接给游戏的触摸屏（覆盖菜单自己的按钮仍然优先）；底座模式下按**画面矩形**映射，点到哪儿就是哪儿
  （`DM_TOUCH_DOCKED=screen` 才回到按 1920×1080 屏幕坐标映射的老行为）
- 菜单文案跟随系统语言（中文系统=中文，其它=英文），`env.txt` 里加 `DM_UI_LANG=zh|en` 可强制

## 已知情况 / 常见问题

| 现象 | 说明 |
|---|---|
| **只有 30 fps** | 游戏引擎按固定 1/30 步进跑，GPU 只占 10~14 ms，余量很大——但帧闸门在引擎内部，改不了 |
| 3D 人物/道具发黑 | 这个游戏把贴图拷进 CPU 缓存池后从不清 cache。已在其 profile 里加上 `tex_flush_upload` / `tex_dirty_upload` 解决（本版 APK/profile 已包含） |
| 解压失败 / 空间不够 | 实测 4.27 GB 解压 22 秒；失败通常是空间不足（ZIP 4.27 GB + 解压后 4.27 GB ≈ 需 8.6 GB 空闲）或 ZIP 不完整 |
| 菜单文字是英文 | 跟随系统语言：中文系统就是中文；也可在 `env.txt` 加 `DM_UI_LANG=zh` 强制 |
| 装了没图标/闪退 | 确认是 arm64 设备、Android 10+；卸载旧签名版本再装 |
| 存档在哪 | 应用内 `/sdcard/Android/data/org.nx2a.t0100d7f00faaa000/files/saves`；也可用菜单「导出存档」导出到公共目录 |

## 技术细节（想复现/改进的看这里）

- 移植工具：[nx2Android](https://github.com/shirai91/nx2android)（MIT）
- 着色器/贴图：MT Framework，460 个着色器在移植时翻译成 SPIR-V
- 驱动：内置 **Mesa Turnip 25.99.99（sysmem build，Vulkan 1.3.335）**，通过 [libadrenotools](https://github.com/bylaws/libadrenotools) 加载，不需要动系统分区
- 本版针对移植层做的修复（已提上游 PR [#477](https://github.com/shirai91/nx2android/pull/477)）：
  - 内存池分块 256 MB → **254 MB**：部分 gralloc 拒绝正好 256 MB 的 `AHardwareBuffer`，否则每帧要拷 768 MB（30 fps → 2 fps）
  - 覆盖层面板改为在可缓存内存里栅格化，再一次性拷进映射缓冲区（重绘 15~25 ms → 4~6 ms）
  - 重绘时 fence/acquire 等待上限 30 ms，菜单打开时按 vsync 持续重绘
  - 底座模式触控映射到 1920×1080 屏幕像素
- 游戏的 profile（常量、着色器表、两个贴图 key）：上游 PR [#476](https://github.com/shirai91/nx2android/pull/476)

## 交给 Agent 生成数据包（提示词）

数据包要自己从 dump 生成——把下面整段复制给 Claude Code / Codex / Alma 之类的 agent，它就知道该怎么跑、要验到什么程度。
仓库根目录的 [`AGENTS.md`](AGENTS.md) 是同一份，支持该约定的 agent 会自动读到。
里面写了：目标产物、必须由你提供的输入（本体 + `prod.keys`）、带 `--vulkan-driver` 的完整命令、
第一次生成后要补的两个贴图 key、ZIP 打包方式、九条验收标准，以及八种常见失败的判断方法。

<details>
<summary>展开：完整的「生成数据包」提示词</summary>

> 复制这一整篇给 coding agent。任务：用 [nx2Android](https://github.com/shirai91/nx2android) 的 `porter`，从**用户自己 dump 的游戏**生成这个移植需要的数据包（和能直接导入的 ZIP），并在设备上验证到「能进游戏、贴图正常」。


### 目标产物

| 产物 | 说明 |
|---|---|
| `<Game>-data/` | 数据目录：**3.97 GiB / 约 5,200 文件**（RomFS、mods、env.txt、空 saves） |
| `<Game>-data.zip` | **store 模式**（不压缩），给应用内导入用 |
| `<Game>.apk` | 可选：27.7 MB，**内含 Turnip 驱动** |
| 验证记录 | 启动日志关键行 + 至少一张游戏内截图 |

### 输入（必须由用户提供，agent 不得自行寻找或下载）

1. **游戏本体**：XCI 或 NSP —— 用户从自己的主机 dump
2. **`prod.keys`** —— 用户从自己的主机 dump（`Lockpick_RCM` 之类）
3. 放游戏的目录（含 `.xci` 或 `.nsp`，更新/DLC 可一并放在同目录）
4. 环境：**Python 3.11+**、**Android NDK**（porter 自动找）、**JDK**（`d8` 需要）

> 拿不到 1/2 就停下来问，不要用网上找的 keys 或游戏文件。

### 步骤（全部实测过）

#### 1. 取工具

```bash
git clone https://github.com/shirai91/nx2android.git      # 握手失败就多重试几次
cd nx2android
py -m pip install -r requirements.txt
```

#### 2. 先看能不能识别

```bash
py -m porter inspect /path/to/game-folder
```

未支持的游戏会打印 `no game profile for <TITLE_ID>` 并以**退出码 1** 结束——这是正常的，不是崩溃，下一步加 `--experimental` 即可。

#### 3. 生成（**必须带 `--vulkan-driver`**）

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'; $env:PATH="$env:JAVA_HOME\bin;$env:PATH"
py -m porter port /path/to/game-folder -o out -k /path/to/prod.keys --experimental `
    --vulkan-driver path/to/vulkan.ad07xx.so --progress lines
```

- **不带 `--vulkan-driver`**：APK 只有 3.96 MB、没有内置驱动。原厂 Adreno 实测 `Vulkan 1.1.128`，启动即 `FATAL [vk] the device has neither dynamic rendering nor imageless ...` 退出
- 驱动从哪来：本仓库 Release 的 APK 里解出 `lib/arm64-v8a/libsysmem_vulkan.ad07xx.so`（16.36 MB）
- 忘了设 `JAVA_HOME` → `d8.bat exit code 1 / JAVA_HOME is not set`

#### 4. 补两个贴图 key（第一次生成后**必做**）

第一次 `porter port` 会在 `<游戏目录>/<TITLE_ID>_build/profile/<TITLE_ID>/game.tsv` 生成一份 survey 出来的 profile，往里面加两行：

```
tex_flush_upload	on
tex_dirty_upload	on
```

再跑一次同样的命令（会复用这份 profile，日志里能看到 `reusing the provisional profile`）。

不补的后果：这个游戏把贴图拷进 CPU 缓存池后从不刷 cache → **3D 人物和道具全黑**（背景和 UI 正常，很容易以为是驱动问题）。

#### 5. 打成 ZIP（给应用内导入）

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
  "out/<Game>-data", "out/<Game>-data.zip",
  [System.IO.Compression.CompressionLevel]::NoCompression, $true)
```

- 必须 **store**：RomFS 里的资源本来就压过了，Deflate 只是白烧 CPU（实测 store 解压 4.27 GB 只要 **22 秒**）
- 顶层目录保持 `<Game>-data/`，应用内导入会自动剥掉这一层

### 验收（逐条对比）

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

### 红线

1. 不许下载或使用别人的 `prod.keys`、游戏 dump、预打包数据包
2. 不许把游戏数据、keys、XCI/NSP 提交进任何 git 仓库
3. 报告里可以写路径和命令，**keys 一律不写**
4. 数据包内容不对就重跑，不要手改 RomFS 里的文件

### 常见失败与判断

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

</details>

## 致谢

- [shirai91/nx2android](https://github.com/shirai91/nx2android)——移植工具链（MIT）
- [Mesa / Turnip](https://gitlab.freedesktop.org/mesa/mesa)——开源 Adreno Vulkan 驱动
- [libadrenotools](https://github.com/bylaws/libadrenotools)——驱动热加载（BSD-2-Clause）
- 界面字体：Ark Pixel / Cubic 11 / Galmuri（SIL OFL）
