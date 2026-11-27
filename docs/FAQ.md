# 常见问题

## 刷完卡在 MI logo（卡米）怎么办

1. TWRP 里先 **清除 Cache/Dalvik** 再重启（有时是假象）
2. 还卡就回滚：
   ```
   fastboot flash boot boot_stock.img
   ```
3. 千万别在没备份的情况下反复刷

## 为什么 su 提示 "inaccessible or not found"

两种原因：

1. 该 App 的 UID 不在白名单 → 见 [AUTHORIZE.md](AUTHORIZE.md)
2. 内核的 hook 没覆盖到 `execveat`（v0.1.0 之前的构建有这个问题，已修）

## 管理器里点「超级用户」弹「更新 App Profile 失败」

**已知问题。** 管理器没有把 `SET_APP_PROFILE` 发给内核（1380 条 ioctl 里一条都没有），
在客户端就放弃了。当前请改用 UID 白名单授权。

## 管理器显示「超级用户 0」，但我明明加了白名单

- 确认文件路径是 `/data/adb/ksu/ksu_uids.txt`（在 ksu 目录里，不是 `/data/adb/` 根目录）
- 确认每行只有数字
- **重启一次**（内核在 init 上下文读取成功率更高）
- 仍不行 → 抓 `dmesg | grep "uid list"` 看是 `open failed` 还是 `applied=0`

## 能不能用 Magisk 的模块

KSU 模块机制与 Magisk 兼容，大部分模块可以直接用；但涉及 `magisk` 专属路径的（如某些 Magisk 二进制调用）可能失败。

## 会不会影响 OTA

会。OTA 会覆盖 boot，root 丢失；更新前建议先刷回官核，更新完再刷本内核。

## 支持哪些机型

当前只验证 **Mi 10 (umi)**。同 SoC 的 cmi / cas / lmi / thyme / apollo 理论可复用，
但需要各自的 defconfig 与面板参数，未验证。
## 官方把管理器更新到 35000 了，我能升级吗

**不能**。官方新源（git.zako.shirkneko.top:20004）里的 v3.0.0 _35000 / manager-ci _35106
对应 **main 树（LKM/GKI）新协议**，我们 builtin 4.19 内核侧版本是 `30000`，装 35000 会直接提示「需要更新内核」。

- 保持 30000 管理器 + 30000 内核
- 如果已经误装 35000：`adb shell pm uninstall com.sukisu.nova` 后重装 30000
- 30000 APK 备份：`adb shell pm path com.sukisu.nova` → `adb pull`

