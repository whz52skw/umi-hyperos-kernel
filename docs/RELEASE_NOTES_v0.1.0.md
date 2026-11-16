# v0.1.0 — 首次可用的自编译内核（Mi 10 / HyperOS 1.0）

## 这是什么

面向 **Xiaomi Mi 10 (umi) + HyperOS 1.0.7.0.TJBCNXM (Android 13)** 的 4.19 自编译内核，
集成 **SukiSU Nova v3.0.0 (30000, builtin 树 + 手动 hook)**。

## 已验证可用

- ✅ 开机稳定、可当主力机
- ✅ `su` 可用：`adb shell su -c id` → `uid=0(root) context=u:r:ksu:s0`
- ✅ MT 管理器内 `su` 可用
- ✅ 管理器识别内核版本 / 模块列表 / Zygisk
- ✅ 驱动 fd 正常发放（`install fd for manager`、`[ksu_driver_su] fd installed`）

## 已知问题

- ❌ **管理器 UI 里的「超级用户」开关写不进去**（弹「更新 App Profile 失败」）。
  证据：1380 条 ioctl 中没有 `SET_APP_PROFILE`，管理器客户端就放弃了。
- ❌ `/data/adb/ksu/.allowlist` 从不生成 → 内核 allowlist 为空
- ⚠️ 文本白名单 `/data/adb/ksu/ksu_uids.txt` 读取被 SELinux 拒绝（`EACCES -13`），下一版验证
- ⚠️ KPM / SUSFS / CPU 伪装 等扩展功能未开启（SUSFS 需 2.x 移植）

## 当前授权方式

1. 用 root 文件管理器创建 `/data/adb/ksu/ksu_uids.txt`
2. 一行一个 UID，例如 `10302`
3. 重启一次，让内核在 init 上下文读取

## 刷入

```
fastboot flash boot boot_stock.img   # 先回官核
# TWRP → Install → Kernel_MIUI_umi_*.zip
```

回滚：`fastboot flash boot boot_stock.img`

## 求帮忙

最需要的是 **让 UI 授权可用**（对齐 main 树的 supercall 协议）与 **SUSFS 2.x 移植到 4.19**，
详见仓库 `docs/ROADMAP.md`。
