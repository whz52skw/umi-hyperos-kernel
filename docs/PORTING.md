# 移植与攻坚计划（UI 授权 / SUSFS 2.x）

本文给出两条最难的路线：**让管理器 UI 授权可用** 与 **SUSFS 2.x 移植到 4.19**。
每条都写清：现状证据、要改哪些文件、验证方法、大概工作量、风险。

---

## 一、UI 授权（P0）

### 现状（已有证据）

- 管理器会问这些 feature：`0(su_compat), 1(kernel_umount), 4(susfs), 16(mount_hide), 10003`
- `10003` 原本返回 `invalid feature_id`（表上限），已加兼容：入口直接返回 `ksu_f10003` 的值
- 1380 条 ioctl 统计里 **没有 `SET_APP_PROFILE(0x40004b0c)`**，说明点击授权时管理器没有发出写入请求
- `/data/adb/ksu/.allowlist` 始终不存在 → 内核 allowlist 恒为空

### 判断

管理器的授权流程大概率是：
1. 读内核 feature/UAPI 版本，判断"是否支持 App Profile 写入"
2. 支持 → 调 `SET_APP_PROFILE`（或写文件后通知内核）
3. 不支持 → 直接弹失败（不发任何写入命令）

所以我们卡在 **第 1 步**。`10003` 很可能就是"profile 写入能力/版本"的探针。

### 实验方案（不需要反复重编）

已加入 `8o`：`10003` 的返回值改成一个 **可调 module 参数**：

```
/sys/module/kernelsu/parameters/ksu_f10003
```

在手机上（有 root）依次试：

```bash
echo 1 > /sys/module/kernelsu/parameters/ksu_f10003
echo 2 > /sys/module/kernelsu/parameters/ksu_f10003
echo 3 > /sys/module/kernelsu/parameters/ksu_f10003
echo 0x7fffffff > /sys/module/kernelsu/parameters/ksu_f10003   # 若 shell 不支持十六进制，用十进制 2147483647
```

每改一次 → 重开管理器 → 点一次授权，观察：
- 是否开始出现 `ksu ioctl: cmd=0x40004b0c`（说明它开始写了）
- 是否还报错

### 如果仍然不发命令

那就说明管理器还检查了别的东西（最可能是 **UAPI 版本** 或 **extension caps**）。下一步：

1. 抓 `GET_INFO` / `GET_FULL_VERSION` 的返回值，与 main 树对比
2. 对比 main 与 builtin 的 `uapi/supercall.h`，看是否缺少 `SET_ALLOW_LIST` 之类的命令
3. 必要时实现一个"最小兼容层"：把管理器期望的命令映射到 builtin 的 `ksu_set_app_profile`

### 工作量

- 若只是 10003 的数值问题：**0.5 天**
- 若需要补 ioctl：**2–4 天**（要看管理器到底用哪些）
- 需要技能：C、KernelSU supercall 协议、会看 dmesg

---

## 二、SUSFS 2.x 移植（P2）

### 现状

- 内核树自带 SUSFS **v1.5.7**（`SUSFS_VERSION` 在 dmesg 可见）
- Nova 的 `CONFIG_KSU_SUSFS` 期望 2.x API，缺这些函数：
  `susfs_add_sus_map`、`susfs_set_priority_uid_filter`、`susfs_start_sdcard_monitor_fn`、
  `susfs_add_sus_path_loop`、`susfs_set_hide_sus_mnts_for_non_su_procs`、
  `susfs_set_avc_log_spoofing`、`susfs_get_enabled_features`、`susfs_add_sus_type`
- 上游只提供 `50_add_susfs_in_kernel-4.19.patch`（1.x 时代），2.x 只有 3.10 的移植参考

### 路线

1. **拿参考**：`SukiSU-Nova/SukiSU_patch` 的 `3.10/0001-SUSFS-port-v2.4.0-to-Linux-3.10.patch`，
   以及 `susfs4ksu` 的 `kernel-4.19` 分支
2. **新建分支**（不要在主分支上试）：
   ```
   git checkout -b susfs2-port
   ```
3. **先移除旧 1.5.7**：反向应用当年的 SUSFS 补丁，或直接对比 `fs/susfs.c` 与 `include/linux/susfs*`
4. **移植核心**：`fs/susfs.c`、`include/linux/susfs.h`、`susfs_def.h`
5. **逐个子系统挂钩**（按风险从低到高）：
   - `fs/stat.c` / `fs/namespace.c`：SUS_KSTAT / SUS_MOUNT（1.x 已有，先保住）
   - `fs/readdir.c`：隐藏目录项
   - `fs/open.c`：OPEN_REDIRECT
   - `security/selinux/avc.c`：avc log spoofing
   - `drivers/mmc` / sdcard monitor：2.x 新增
   - `fs/proc/task_mmu.c`：SUS_MAP（隐藏 maps）
6. **对齐 Nova 的扩展**：`extension/susfs_extension.c` 里调用的 `susfs_*` 必须全部有实现
7. **打开配置**：`susfs_mode=on` + 相应子项，编译验证
8. **功能验证**：装 `susfs4ksu-module`，用 `ksu_susfs show version` / `show sus_path` 验证

### 工作量与风险

| 阶段 | 熟手 | 新手 |
|---|---|---|
| 理解 3.10 移植与 4.19 差异 | 0.5–1 天 | 3–5 天 |
| 移除旧 1.5.7 | 0.5 天 | 1–2 天 |
| 核心编过 | 1–2 天 | 3–5 天 |
| 钩子逐个接 | 2–4 天 | 1–2 周 |
| 与 Nova 接口对齐 | 1 天 | 2–3 天 |
| 联调（10–20 轮编译+刷机） | 2–3 天 | 3–5 天 |

**合计：熟手 5–8 个工作日；新手 2–3 周。** 中途刷砖风险高，务必每轮都留 boot 备份。

> 更省事的替代：直接用作者 2026-07-15 的预编译包 + 管理器 3.2.0，
> 那套 SUSFS 1.5.7 已验证可用，只是管理器不能更新。

---

## 三、优先级建议

1. **先做 10003 数值实验**（可能 30 分钟就能让 UI 授权可用）
2. UI 通不了再考虑补 ioctl（2–4 天）
3. SUSFS 2.x 放到最后（周级别）
4. 期间用 `ksu_uids.txt` 白名单维持可用
