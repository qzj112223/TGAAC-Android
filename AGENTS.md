# AGENTS.md — 交给 agent 的开工提示词

> 直接复制这一整篇给 coding agent（Claude Code / Codex / Alma Task 都行）。
> 它包含：项目背景、环境实测结果、不要碰的红线、四件待办 + 各自的验收标准。

---

## 你是谁，要做什么

你接手的是一个 **nx2Android 生成的 Android 原生移植的分发仓库**：Switch 版《大逆转裁判 1&2》在 Android 上跑（不是模拟器，是把游戏的 ARM64 代码翻译成 C 再编译成原生程序）。

- 本仓库（`TGAAC-Android`）**只放构建好的 APK 和文档**，不放游戏数据
- 生成它的是上游工具 [shirai91/nx2android](https://github.com/shirai91/nx2android)（MIT）
- 本仓库的 APK 比上游 HEAD 多两个**尚未合并**的 PR 的修复：profile [#476](https://github.com/shirai91/nx2android/pull/476)、代码 [#477](https://github.com/shirai91/nx2android/pull/477)

## 红线（违反即失败）

1. **绝不提交**游戏数据、`prod.keys` / `title.keys`、XCI/NSP、任何从游戏提取的资源
2. **不改** `LICENSE`、`DISCLAIMER.md` 让条款变松；改文案只能更严格
3. 不要把 4 GB 的数据包或其分卷提交进仓库（GitHub 单文件 2 GB 上限）
4. 改 APK 必须**同时**更新 README 里的「构建时的三个坑」说明，不要留下对不上的文档

## 环境（Windows 11，已实测）

| 项 | 值 |
|---|---|
| Python | 3.12，用 `py` 启动器 |
| JDK | `C:\Program Files\Android\Android Studio\jbr` — **必须** `setx JAVA_HOME` 并把它加进 PATH，否则 `d8` 报 `JAVA_HOME is not set` |
| NDK | 28.2.13676358（porter 自动找） |
| SDK | `%LOCALAPPDATA%\Android\Sdk`，build-tools 35.0.0 |
| 设备 | OPPO Pad OPD2101 / 骁龙 870 / Adreno 650 / Android 15，adb 有线或无线（`adb connect <ip>:<port>`） |
| 包名 | `org.nx2a.t0100d7f00faaa000` |
| 数据目录 | `/sdcard/Android/data/org.nx2a.t0100d7f00faaa000/files/`（RomFS + env.txt + saves） |

**构建一条命令**（在 nx2android 源码根目录）：

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'; $env:PATH="$env:JAVA_HOME\bin;$env:PATH"
py -m porter port "E:\aiam" -o "E:\aiam\port-out" --experimental `
    -k "E:\aiam\23.5.0\prod.keys" --jobs 8 `
    --vulkan-driver "E:\aiam\nx2android-port\sysmem_vulkan.ad07xx.so" `
    --data-import --progress lines
```

产出：`TheGreatAceAttorneyChronicles.apk`（27.7 MB）+ `TheGreatAceAttorneyChronicles-data/`（4.0 GB / 5,206 文件）。

**别踩的坑（都实测过）**
- 不带 `--vulkan-driver` → APK 只有 4 MB，没有内置驱动，原厂 Adreno（Vulkan 1.1）会直接 abort
- 自己 survey 出来的 profile 缺 `tex_flush_upload` / `tex_dirty_upload` → 3D 人物和道具全黑
- `porter inspect` 对未支持的游戏退出码是 1，不是崩溃
- `git clone` 在国内网络会 `schannel: failed to receive handshake`，要重试

## 现状（2026-11-21）

**已解决**
- 覆盖菜单拖动顿卡：三个原因全修（菜单打开时 present 线程按 vsync 重绘；fence/acquire 等待上限 30 ms；面板改为在可缓存内存栅格化再一次性拷进映射缓冲区）
- 3D 人物发黑：profile 加两个贴图 key
- 内存池：`ZC_CHUNK` 256 MB → 254 MB（部分 gralloc 拒绝正好 256 MB 的 `AHardwareBuffer`，否则每帧拷 768 MB，30→2 fps）
- 底座模式触控、中英双语 UI、应用内选择数据包 ZIP + 免费使用声明

**已知未解**
- **只有 30 fps**：引擎内部按 1/30 固定步进；`main.bin` 里没有 `1/30` 浮点常量，`0x9b3f1c` 的 `1/60` 只用于 tick→秒；`DM_VSYNC_HZ=120` 无效；FPSLocker-Warehouse 没有这个 build 的配置
- 设备偶发 lmkd SIGSEGV
- 系统级 Turnip 模块已生效（`Turnip Adreno (TM) 650 / Vulkan 1.3.363`），但那是 root 侧的事，与 APK 无关

## 待办（按优先级）

### 1. 跟进上游 PR（最高优先，阻塞其它人）
- [#476 profile](https://github.com/shirai91/nx2android/pull/476)（8 文件，+751）、[#477 代码](https://github.com/shirai91/nx2android/pull/477)（8 文件，+141/−50）
- 有 review 就按意见改；上游 `origin/main` 前进后 `git rebase --onto origin/main 8fe846b`
- **验收**：两个分支都能从最新 `origin/main` 干净 rebase、`py -m porter port` 能编过、diff 里没有二进制文件、提交信息按仓库惯例（`feat(android): ...` / `fix(vk): ...`）

### 2. 60 fps（技术上最硬）
- 先复现：`--progress lines` 构建，跑游戏，覆盖层确认稳定在 30.0 fps，`[vk]` 帧耗时 10~14 ms（GPU 有大量余量，瓶颈在引擎的帧闸门）
- 调查方向（按可能性）：① hook `nvsw` 的 vsync 等待 / `nvn` 的 present interval；② `game.tsv` 里有没有 tick/decouple 相关开关；③ 引擎内部 `nn::os::Sleep` 的 33.3 ms 调用点（`DM_SLEEP_BT` 已能看到）
- **验收**：覆盖层 FPS ≥ 55 且**不加速**（对话/动画时长正常，存档时钟正常）；`[RED]` 计数为 0；不能靠插帧糊过去

### 3. lmkd SIGSEGV / 后台被杀
- `adb shell dmesg | grep -i lmkd`、`/data/anr/traces.txt`、`/data/tombstones/`
- 先判定是 ROM 问题还是本移植的堆行为（`[mem] heap 3.14 GB`）
- **验收**：能给出「是/不是本移植引起」的明确证据链，是则给最小复现步骤

### 4. 数据包分发
- 现在靠 PowerShell 一行打不压缩 zip；可给 porter 加 `pack` 子命令（`py -m porter pack <data 目录> -o x.zip`），带进度、支持拆卷（`--split 1500M`）
- **验收**：`pack` 产出的 zip 能被应用内导入直接吃掉（含顶层目录自动剥除）；拆卷后有对应的合并说明且在 Windows/PowerShell 与 Linux 两条路径都验证过

## 怎么找东西

- 覆盖层渲染：`nxnative/dm/android/gfx_vk_present.c`（i18n 在 `overlay_layout.h`）
- 触控：`nxnative/dm/host/hle_touch.c` + `nxnative/dm/android/front_android.c`
- 内存池：`nxnative/dm/android/gfx_vk_core.c`（`ZC_CHUNK`）
- profile：`nxnative/dm/games/0100D7F00FAAA000/`（8 个 TSV，`game.tsv` 是关键开关）
- 本机资料（如果在这台机器上）：`E:\aiam\nx2android-port\src`（源码）、`E:\aiam\port-out`（构建产物）、`E:\aiam\bootwork`（原厂 boot 备份，**不要删**）

## 交付方式

- 代码改动 → 分支 + PR，一个 PR 一件事，别把 profile 和代码混在一起
- 每次改完在设备上实测，把「命令 + 输出 + 截图/日志关键行」写进 PR 描述
- 不确定的地方先问，不要猜着改
