# 交接全书（HANDOVER）

> ⛔ 项目无期限停更。本文是给接手者的**全部作战档案**：我们是谁、做到哪、卡在哪、下一步怎么干、工具在哪。
> 读完本文（约 30 分钟）你就能无缝接手。

---

## 0. 三句话简介

1. 目标：让 **SukiSU Nova**（KernelSU 系 root 方案）跑在 **小米10 (umi, SM8250, 非 GKI)** 的 **4.19 老内核**上——官方已经放弃这条路，我们是最后一批自己动手的人。
2. 现状：**已成功**。自定义编译内核 + SukiSU Nova builtin 3.0.0 (30000)，root 可用、管理器可识别、日常稳定。
3. 遗留：**管理器 UI 授权**（点「超级用户」开关失败）和**白名单加载**（被 SELinux 拦）两个尾巴未闭环，正文给出完整的攻破路径。

## 1. 设备与组合

| 项 | 值 |
|---|---|
| 设备 | Xiaomi Mi 10 (umi) / HyperOS 1.0.7.0.TJBCNXM / Android 13 |
| 内核 | 4.19.325（base: `liyafe1997/kernel_xiaomi_sm8250_mod` 分支 `android15-lineage22-mod`） |
| Root | SukiSU Nova v3.0.0 (30000)，`SukiSU-Nova/SukiSU-Nova` 分支 `builtin`（commit `4bec532`），手动 hook 模式 |
| 管理器 | `SukiSU_Nova_v3.0.0_30000-release.apk`（**官方渠道已绝版，仓库 Release v0.2.0-archive 有备份**） |
| 构建 | GitHub Actions（`.github/workflows/build.yml`，31 步），或本地 Ubuntu 22.04（见 BUILDING.md） |

## 2. 已完成（可信）

- [x] 编译链：4.19 全兼容补丁（static_call.h shim、KSU_NO_PREINIT 守卫、access_ok 三参、hook 位置、fd 安装时机…）→ 31 步 workflow
- [x] root 可用：`adb shell su -c id` → `uid=0(root) context=u:r:ksu:s0`
- [x] su 拦截链路：`do_execveat_common` 钩子 + su 会话 fd 安装（dmesg 实证）
- [x] 管理器识别：`30000-6 / Manual Hook`、模块列表、Zygisk
- [x] 开源仓库 + 全套文档 + 排错记录（docs/DIAGNOSIS.md 有 10 个坑）
- [x] 官方动向摸清：**builtin 分支 2026-11-15 停更；官方发布源迁至 `git.zako.shirkneko.top:20004` 与 CNB；管理器升到 35000/35106/41150（main 树协议）**

## 3. 未完成（两个尾巴）

### 3.1 管理器 UI 授权（P0，主要遗留问题）

现象：管理器里给应用点「超级用户」→ 弹「为 xxx 更新 App Profile 失败」。

已定位的证据链（重要，接手人直接抄）：
1. 1380 条 ioctl 日志中 **没有 `SET_APP_PROFILE (0x40004b0c)`** → 管理器客户端直接放弃，没发出写入命令
2. 管理器查询的 feature id：`0(su_compat), 1(kernel_umount), 4(susfs), 16(mount_hide), 10003`
3. `10003` builtin 原本报 `invalid feature_id`（表上限 KSU_FEATURE_MAX 太小）；已在函数入口打桩返回支持
4. `/data/adb/ksu/.allowlist` 从不生成 → 内核 allowlist 恒空（管理器写的是 `/data/adb/ksu/profile/`，内核不读）
5. 怀疑：`10003` 是"App Profile 能力/版本"探针，我们返回 `1` 可能被判定为不支持

**下一步攻击路径（见 docs/FLOW.md 流程图）：**
- 阶段 0（静态）：JADX 反编译 30000 管理器，找 `10003`、`SET_APP_PROFILE`、GET_FEATURE 解析逻辑 → 确定它要什么值
- 阶段 1（动态）：编带 8o 的内核（workflow 已含），`/sys/module/kernelsu/parameters/ksu_f10003` 遍历 1/2/3/2147483647，配合 `tools/diagnostics.ps1` 一键抓 strace + dmesg
- 阶段 2（首攻）：按证据补数值 / 补 ioctl handler（映射到 `ksu_set_app_profile()`）/ 放开签名校验
- 阶段 3（终招）：伪造内核版本号（30000→35106/41150）观察新协议调用面；或移植 main 树的 profile 写入接口

### 3.2 文本白名单加载（P1）

现象：内核读 `/data/adb/ksu_uids.txt` 返回 `EACCES -13`（SELinux 拒绝，因为读取发生在管理器进程的应用上下文）。

处理：
- 已把路径迁到 `/data/adb/ksu/ksu_uids.txt` 并加了完整日志（8m v2，workflow 第 20 步）
- **未验证**（停更前未能编译刷机）

验证命令（接手者第一步）：
```bash
adb shell "su -c 'echo 10302 > /data/adb/ksu/ksu_uids.txt'"
adb reboot   # 让 init 上下文读取（比应用上下文权限宽）
adb shell "su -c dmesg" | grep "uid list"
# 期望：ksu: uid list open failed ... 或  ksu: uid list loaded, bytes=N applied=N
```

若仍 EACCES：可尝试 `override_creds(ksu_cred)` 读取，或把文件放 `/data/local/tmp`，或在 sepolicy 里给相关 domain 加 read 权限。

## 4. 仓库结构

```
.github/workflows/build.yml   31 步构建（全部内核补丁都在这里，逐条可读）
docs/HANDOVER.md              本文
docs/STATUS.md                逐项状态 + 日志证据
docs/DIAGNOSIS.md             10 个坑的排错全记录
docs/FLOW.md                  流程图（Mermaid）
docs/ROADMAP.md               接手任务清单
docs/FAQ.md / AUTHORIZE.md / HARDWARE-TEST.md / DEVICE-INFO.md / PORTING.md
tools/diagnostics.ps1         一键诊断（strace + 10003 遍历 + 打包）
tools/get-jadx.ps1            一键装 JADX + 导出管理器 APK
patches/README.md             8b~8n 补丁对照表
```

## 5. 关键文件与符号（内核补丁落点）

| 补丁 | 文件 | 作用 |
|---|---|---|
| 8g | `fs/exec.c` | hook 移到 `do_execveat_common` + su 会话 fd 安装 |
| 8i | `KernelSU/kernel/policy/allowlist.c` | 硬放行 uid 2000/10302（dev 妥协） |
| 8j | `policy/feature.c` | feature 10003 入口直接放行 |
| 8k | `supercall/dispatch.c` | ioctl 全量日志 |
| 8l | `supercall/dispatch.c` | allowlist 热加载（1s 限频） |
| 8m | `policy/allowlist.c` | 读 `/data/adb/ksu/ksu_uids.txt` 注入（v2 带日志） |
| 8n | `policy/feature.c` | 打印所有 feature 查询 id |
| 8o | `policy/feature.c` + `dispatch.c` | `ksu_f10003` 可调参数 + 未匹配 ioctl 日志 |

符号自检（workflow 10b 步自动做）：`ksu_load_uid_text_file`、`ksu_allowlist_reload`、`ksu_f10003`、`ksu_compat_feature_10003`

## 6. 配套管理器（重要）

- 本项目内核（30000）**只能配 30000 管理器**，装 35000/35106/41150 会报「需要更新内核」
- 官方渠道已无 30000 APK → **仓库 Release `v0.2.0-archive` 已备份**（含 `SukiSU_Nova_v3.0.0_30000-release.apk` 与 `SukiSU_v3.2.0.apk`）
- 双版本 SHA-256 见 Release 说明

## 7. 接手者 30 分钟导读

1. 读本文（5 分钟）
2. 读 docs/STATUS.md + DIAGNOSIS.md（10 分钟）——答案都在里面
3. 看 workflow 的 8b~8o 步（5 分钟）——所有补丁即代码
4. 跑一次 Actions 编译（后台）→ 刷机 → 验证 root（5 分钟）——确认环境可复现
5. 按 docs/FLOW.md 从阶段 0 开始攻 UI 授权（剩余 10 分钟规划）

## 8. 免责与许可

- 仅含 GPL 源码补丁与构建脚本，不含任何厂商固件
- 刷机风险自负；每轮实验前备份 boot
- 接手即默认延续 GPL-2.0 许可
