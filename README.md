# Mi 10 (umi) HyperOS 自编译内核 + SukiSU Nova

面向 **Xiaomi Mi 10 (umi) / HyperOS 1.0.7.0.TJBCNXM (Android 13) / 内核 4.19** 的自编译内核工程，
目标是让 **SukiSU Nova (v3.0.0 / 30000)** 在这台非 GKI 老内核设备上可用。

> 结论先说：**root 已经可用**（shell / MT 管理器），但**管理器 UI 里的「超级用户」开关写不进去**——
> 这是本工程当前最大的未解问题，也是最需要社区帮忙的地方。详见 [docs/STATUS.md](docs/STATUS.md)。

---

## 1. 设备与环境

| 项 | 值 |
|---|---|
| 机型 | Xiaomi Mi 10 (codenames: **umi**) |
| SoC | Qualcomm SM8250 (骁龙 865) |
| 系统 | HyperOS 1.0.7.0.TJBCNXM / Android 13 / SDK 33 |
| 指纹 | `Xiaomi/umi/umi:13/TKQ1.221114.001/V816.0.7.0.TJBCNXM:user/release-keys` |
| 原厂内核 | 4.19.157-perf-g8e1dce01cadc |
| 编译内核 | 4.19.325-YYYYMMDD-<commit>-perf+ (LineageOS 22 base) |
| Root 方案 | SukiSU Nova v3.0.0 (30000), **builtin 树 + 手动 hook** |
| 分区 | A-only，独立 recovery 分区，boot 分区刷 AnyKernel3 |

## 2. 当前状态（重要）

| 功能 | 状态 | 说明 |
|---|---|---|
| 开机 / 日常使用 | ✅ | 稳定，可当主力机 |
| `su`（adb shell / MT 管理器） | ✅ | 需要 UID 白名单（见第 3 节） |
| 管理器基本功能 | ✅ | 版本、模块列表、Zygisk 识别、App Profile 读取 |
| **UI 授权（超级用户开关）** | ❌ | 管理器不发送 `SET_APP_PROFILE`，疑似特性/接口缺失，**待解决** |
| KPM | ⚠️ | 编译时 `kpm_mode=on` 即可开 |
| SuSFS | ❌ | 源码树 SUSFS 为 v1.5.7，Nova 需要更新一代 API，需移植 |
| Umount 路径 / 动态管理器 / 版本伪装 | ⚠️ | 内核已注册 extension，管理器侧显示“不支持”，疑似 feature 桩缺失 |
| CPU 身份伪装 | ⚠️ | 需 `KSU_CAN_USE_CPU_SPOOF` 条件满足，未验证 |

## 3. 怎么授权（当前唯一可用方式）

内核每次刷新 allowlist 时会读取：

```
/data/adb/ksu/ksu_uids.txt
```

格式：纯文本，一行一个 UID（只写数字）：

```
10302
10123
```

- 用任意 root 文件管理器创建/修改
- 重新打开管理器即可触发热加载（无需重启）
- 管理器「超级用户」列表会显示这些应用（读的是同一份 allowlist）

> ⚠️ 已知问题：内核以 init 上下文读取 `/data/adb/ksu_uids.txt` 时被 SELinux 拒绝（`EACCES -13`）。
> 已把路径迁移到 `/data/adb/ksu/` 并加日志，等待下一版验证。详见 [docs/DIAGNOSIS.md](docs/DIAGNOSIS.md)。

## 4. 构建

见 [BUILDING.md](BUILDING.md)。两种方式：

1. **GitHub Actions（推荐）**：fork 本仓库 → Actions → Run workflow
2. **本地 Ubuntu 22.04**：需要 40GB 空间、proton-clang 20210522

## 5. 产物说明

- `Kernel_MIUI_umi_*.zip`：HyperOS/MIUI 用，**刷这个**
- `Kernel_AOSP_umi_*.zip`：第三方 AOSP ROM 用
- 两者都是 AnyKernel3 包，只替换 boot 内的 Image，不刷 dtb、不刷模块

## 6. 已解决的关键问题（供后来者参考）

1. **Nova 3.0 是给 GKI/main 树写的**，在 4.19 上必须用 `builtin` 分支（手动 hook）
2. `linux/static_call.h` 在 4.19 不存在 → 需要 shim
3. `KSU_NO_PREINIT` 宏重复定义 → 需要 `#ifndef` 守卫
4. 4.19 的 `access_ok()` 是三参数 → KPM 代码需要补 `VERIFY_WRITE`
5. **hook 必须放在 `do_execveat_common`**，放在 `do_execve` 会漏掉 `execveat`/`posix_spawn`
6. su 会话 fd 只能在应用上下文（uid >= 10000）安装，否则早期启动直接卡米

## 7. 需要社区帮忙的点

见 [docs/ROADMAP.md](docs/ROADMAP.md)，最紧急的三项：

- [ ] **让 UI 授权可用**：确认管理器查询的全部 feature id，补齐特性桩或实现对应 ioctl
- [ ] **SUSFS 2.x 移植到 4.19**：当前树停留在 1.5.7
- [ ] **KPM / CPU 伪装 / Umount 路径** 等扩展功能的开关对齐

## 8. 免责声明

刷机有风险（变砖、数据丢失、保修失效）。所有操作请自行备份 boot/data。
本项目仅包含 GPL 源码补丁与构建脚本，**不包含任何厂商固件、boot.img、ramdisk**。
