# AGENTS.md — 把产物整合成「下载即用」的压缩包

> 复制这一整篇给 coding agent。任务是**打包与分发**，不是继续改移植层。

---

## 一句话任务

把构建产物（APK + 数据目录）整合成用户**下载 → 解压 → 三步就能玩**的压缩包，并且每一包都验证过。

## 输入（已存在，别重新构建）

| 产物 | 位置 | 大小 |
|---|---|---|
| APK（含 Turnip 驱动） | `E:\aiam\port-out\TheGreatAceAttorneyChronicles.apk` | 27.7 MB |
| 数据目录 | `E:\aiam\port-out\TheGreatAceAttorneyChronicles-data\` | 3.97 GiB / 约 5,200 文件 |
| 文档与脚本 | 仓库根目录 `README.md` / `DISCLAIMER.md` / `install-windows.bat` / `install.sh` | — |

## 要产出的两个包

### A. 单文件分发包（放网盘）

```
TGAAC-Android-v1.0.0.zip
└─ TGAAC-Android-v1.0.0/
   ├─ TheGreatAceAttorneyChronicles.apk
   ├─ data/TheGreatAceAttorneyChronicles-data.zip      4.27 GB（store，不压缩）
   ├─ README.md
   ├─ DISCLAIMER.md
   ├─ install-windows.bat
   ├─ install.sh
   └─ SHA256SUMS.txt
```

```powershell
# 数据包（必须是 store：RomFS 已压缩过，Deflate 只是白烧 CPU）
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
  "E:\aiam\port-out\TheGreatAceAttorneyChronicles-data",
  "E:\aiam\dist\data\TheGreatAceAttorneyChronicles-data.zip",
  [System.IO.Compression.CompressionLevel]::NoCompression, $true)

# 校验清单（UTF-8 无 BOM，sha256sum 能直接 -c）
Get-FileHash ... -Algorithm SHA256
```

### B. 分卷包（只能放 GitHub Release 之外的私链；见红线 1）

每卷 < 1.9 GB（GitHub 单文件上限 2 GB，留余量），固定命名 `part-aa/ab/ac…`：

```powershell
7z a -mx0 -v1700m TheGreatAceAttorneyChronicles-data.7z "E:\aiam\port-out\TheGreatAceAttorneyChronicles-data"
# 或对已有 zip 分卷：split -b 1700M（WSL/Git Bash）
```

同时给出合并脚本，两个平台都要：

```bat
:: join-windows.bat
copy /b part-aa + part-ab + part-ac TheGreatAceAttorneyChronicles-data.zip
```

```bash
# join.sh
cat part-aa part-ab part-ac > TheGreatAceAttorneyChronicles-data.zip
```

## 红线

1. **含游戏 RomFS 的数据包不能进公开 GitHub 仓库或 Release** —— GitHub 上只发 APK（27.7 MB），数据包走网盘/私链
2. **不许打包** `prod.keys` / `title.keys` / NSP / XCI / 任何密钥文件
3. 压缩一律 **store / -mx0**，别用默认 Deflate
4. 数据包顶层目录必须正好是 `TheGreatAceAttorneyChronicles-data/`（应用内导入会自动剥掉这一层，多一层少一层都会 `hasData()` 失败）
5. 每个包都带 `SHA256SUMS.txt`；文件名带版本号，不覆盖旧版本

## 验收（一条条跑，别跳）

1. 解压单文件包 → APK、data zip、文档齐全
2. `sha256sum -c SHA256SUMS.txt` 全部 OK
3. 平板上装 APK → 首次启动弹免费使用声明 → 选数据 ZIP → 自动解压 → 进游戏
   （实测参考：4.27 GB / 约 5,200 文件 **22 秒**解完，OPPO Pad UFS）
4. 分卷版：合并后 sha256 与单文件版**完全一致**，且同样能导入
5. 只照 `README.md` 的三步（装 APK / 选 ZIP / 进游戏）能从零玩起来，不需要别的资料
6. 包内搜一遍：无 `*.keys`、无 `*.nsp`、无 `*.xci`

## 环境（实测）

| 项 | 值 |
|---|---|
| 系统 | Windows 11 + PowerShell 7 |
| 7-Zip | `C:\Program Files\UotanToolbox\Bin\7z\7za.exe`（或系统装的 `7z.exe`） |
| 平板 | OPPO Pad（OPD2101），adb 序列号 `cbf19295`，屏幕常亮用 `svc power stayon true` |
| 免费空间 | 单文件包 + 数据包中间产物，E: 至少留 **12 GB** |
| 平板空间 | 导入时 ZIP 4.27 GB + 解压后 4.27 GB，需 **约 8.6 GB** 空闲 |

## 最容易踩的四个坑

1. 用 Deflate 压 4 GB → 半小时起步，还没意义
2. 分卷做成 > 2 GB → GitHub 直接拒收
3. 分卷合并顺序错 / 命名不固定 → zip 打不开（用 `part-aa`、`part-ab`，别用 `part1`、`part10`）
4. 顶层目录多套了一层（`xxx/TheGreatAceAttorneyChronicles-data/...` 之外的再套一层）→ 导入后找不到 RomFS

## 交付

- 产出清单（文件名 + 大小 + sha256）写进 Release 说明或网盘分享页
- 分卷说明里必须写清「怎么合并、怎么校验」，否则用户只能干瞪眼
