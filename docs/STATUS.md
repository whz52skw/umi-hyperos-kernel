# 状态与证据

记录本工程当前的**已验证/未验证**状态，以及每条结论对应的日志证据。

## 环境
- 内核：4.19.325-YYYYMMDD-<commit>-perf+（LineageOS 22 base，MIUI 变体）
- KSU：SukiSU Nova v3.0.0 (30000)，`builtin` 树
- 管理器：SukiSU_Nova_v3.0.0_30000-release.apk（官方签名）
- 管理器 UID：10299 / MT 管理器 UID：10302

## 已验证 ✅

| 项 | 证据 |
|---|---|
| 内核能开机、日常稳定 | 多日使用无重启 |
| su 可用 | `adb shell su -c id` → `uid=0(root) context=u:r:ksu:s0` |
| 管理器识别内核 | 主页显示 `30000-6`、`v3.0.0-4bec532d@builtin`、`Manual Hook` |
| 驱动 fd 发放 | dmesg: `install fd for manager: 10299`、`[ksu_driver_su] fd installed: 3` |
| su 拦截 | dmesg: `do_execveat_common su->ksud!` |
| allowlist 读取 | dmesg: `load_allow_list open file failed: -13`（文件存在但被 SELinux 拒读） |

## 未解决 ❌

### 1. UI 授权失败（最高优先级）
现象：管理器里给应用打开「超级用户」→ 弹「为 XXX 更新 App Profile 失败」。

证据（dmesg + ioctl 全量日志，共 1380 条）：

```
cmd=0xc0004b09 (UID_SHOULD_UMOUNT) 708 次 ret=0
cmd=0xc0004b0b (GET_APP_PROFILE)   646 次 ret=-2
cmd=0xc0004b0d (GET_FEATURE)        15 次 ret=0
cmd=0x4b01    (GRANT_ROOT)           5 次 ret=0
cmd=0xc0044b06(NEW_GET_ALLOW_LIST)   2 次 ret=0
—— 没有出现过 cmd=0x40004b0c (SET_APP_PROFILE) ——
```

结论：管理器**从未把写入命令发到内核**，在客户端就放弃了；且 `/data/adb/ksu/` 下从未生成 `.allowlist`。
推测：管理器要求 main 树的新接口/特性，builtin 树缺失。

### 2. feature 10003
管理器频繁查询 `GET_FEATURE(10003)`，builtin 返回 `invalid feature_id`（因为 `KSU_FEATURE_MAX` 很小）。
已加兼容：在 `ksu_get_feature/ksu_set_feature` 入口直接对 10003 返回支持。
如果尝试扩大 `KSU_FEATURE_MAX`，会导致 `DECLARE_BITMAP` 类型冲突（`forced_mask` 重定义），不要走这条路。

### 3. 文本 UID 白名单被 SELinux 拦截
`/data/adb/ksu_uids.txt` 存在，但内核读取返回 `-13 (EACCES)`。
下一步：迁移到 `/data/adb/ksu/ksu_uids.txt`（该目录在 boot 时内核可穿越）并加日志验证。

## 兼容性补丁清单
见 [../patches/README.md](../patches/README.md)。
