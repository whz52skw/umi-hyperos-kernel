# 路线图（欢迎认领）

## P0 让 UI 授权可用
- [ ] 抓全管理器请求的 feature id（已加日志 `ksu: feature req id=`）
- [ ] 逐个补特性桩，确认管理器是否继续发送 `SET_APP_PROFILE`
- [ ] 如果没有发送：比对 main 树的 supercall 协议，补齐缺失 ioctl
- 需要技能：KernelSU 源码、Kotlin（读管理器侧逻辑）

## P1 白名单可用
- [ ] 把 `ksu_uids.txt` 路径迁到 `/data/adb/ksu/`，处理 SELinux（`override_creds` / 目录标签）
- [ ] 验证热加载：改文件 → 管理器刷新 → 立即生效
- 需要技能：Linux/SELinux、内核文件 IO

## P2 SUSFS 2.x 移植到 4.19
- [ ] 参考 `susfs4ksu` 的 3.10 移植与 main 树用法
- [ ] 移植 fs 钩子：namespace/umount、kstat、readdir、open、sdcard monitor
- [ ] 对齐 Nova 的 `CONFIG_KSU_SUSFS` 扩展接口
- 工作量大，**不建议新手**

## P3 扩展功能开关
- [ ] KPM：`kpm_mode=on` 验证
- [ ] CPU 身份伪装：确认 aarch64 4.19 下 `KSU_CAN_USE_CPU_SPOOF` 条件
- [ ] Umount 路径 / 动态管理器 / 版本伪装：补对应特性

## P4 工程化
- [ ] 把 workflow 里的补丁抽成 `patches/*.patch`，可 `git apply`
- [ ] 提供 `boot.img` 一键打包脚本（mkbootimg 参数）
- [ ] 增加 selftest：开机后自动跑功能表
