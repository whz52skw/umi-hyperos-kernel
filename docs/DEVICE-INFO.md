# 环境信息（用于复现）

## 设备

| 项 | 值 |
|---|---|
| 型号 | Xiaomi Mi 10 |
| 代号 | umi |
| SoC | SM8250 (骁龙 865) |
| 系统 | HyperOS 1.0.7.0.TJBCNXM |
| Android | 13 (SDK 33) |
| 指纹 | `Xiaomi/umi/umi:13/TKQ1.221114.001/V816.0.7.0.TJBCNXM:user/release-keys` |
| 分区 | A-only，独立 recovery |
| 原厂内核 | 4.19.157-perf-g8e1dce01cadc |

## 内核源码

- 基座：`liyafe1997/kernel_xiaomi_sm8250_mod` 分支 `android15-lineage22-mod`
- 版本：4.19.325
- 工具链：proton-clang 20210522 (clang 13.0.0)

## SukiSU

- 管理器：`SukiSU_Nova_v3.0.0_30000-release.apk`（UID 10299）
- 内核侧：`SukiSU-Nova/SukiSU-Nova` 分支 `builtin`，commit `4bec532d`
- 内核版本号：30000

## 关键日志样本

```
KernelSU: LSM hooks initialized.
KernelSU: feature: registered handler for su_compat (id=0)
KernelSU: install fd for manager: 10299
KernelSU: [ksu_driver_su] fd installed: 3 for pid ...
KernelSU: do_execveat_common su->ksud!
KernelSU: load_allow_list open file failed: -13
KernelSU: ksu ioctl: cmd=0xc0004b0b uid=10299 ret=-2
KernelSU: ksu: feature req id=10003
```

## 官方发布源变迁（2026-11-28 记录）

- 官方安装指南的"下载管理器"改指向自建实例：`https://git.zako.shirkneko.top:20004/shirkneko/SukiSU/releases`
- 该源只有 35000 系列 APK（main 树协议），**builtin 30000 内核不可用**
- GitHub Releases 同款 35000（分 ABI 打包）
- 本项目配套版本：`SukiSU_Nova_v3.0.0_30000-release.apk`（从手机提取备份）
