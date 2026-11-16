# 排错记录（按时间顺序）

这份文档记录本工程踩过的所有坑，供后来者直接抄答案。

## 1. Nova 3.0 管理器 + 4.19 内核，管理器报「需要更新内核」
- 现象：内核侧版本 13251，管理器 30000，不兼容
- 原因：作者 build.sh 钉死的是旧 SukiSU 分支
- 处理：改用 `SukiSU-Nova/SukiSU-Nova` 的 `builtin` 分支

## 2. 编译报 `linux/static_call.h: file not found`
- 原因：该头文件 5.10 才引入，Nova 无条件 include
- 处理：在内核树创建空的 `include/linux/static_call.h` shim

## 3. 编译报 `KSU_NO_PREINIT macro redefined`
- 原因：Makefile 传 `-D`，`preinit.h` 又无条件 `#define`
- 处理：头文件加 `#ifndef` 守卫 + KSU 编译加 `-Wno-error`

## 4. KPM 编译报 `access_ok` 参数不足
- 原因：4.19 的 `access_ok` 是三参数宏
- 处理：调用处补 `VERIFY_WRITE`

## 5. main 树报 `MODULE_IMPORT_NS` 未定义
- 原因：该宏 5.4 才引入
- 结论：main 树是为 GKI 写的，4.19 上不建议继续

## 6. 装完无法开机（卡米）——fd 安装时间太早
- 原因：`ksu_install_su_fd()` 在早期启动上下文被调用
- 处理：限制条件 `ksu_is_su && ret >= 0 && ksu_uid >= 10000`（只给应用会话装）

## 7. su 完全不拦截（MT/管理器都不弹框）
- 原因：hook 放在 `do_execve`，而 Android 的 `posix_spawn` 走 `execveat`
- 处理：把 hook 移到 `do_execveat_common`，覆盖 execve/execveat/posix_spawn

## 8. 管理器 UI 授权失败
- 证据：1380 条 ioctl 中没有 `SET_APP_PROFILE`
- 结论：管理器客户端放弃写入，builtin 树缺少其期望的接口
- 状态：未解决

## 9. `/data/adb/ksu/.allowlist` 从不生成
- 说明：普通路径下这个文件由 ksud 写入；本组合中 ksud 不写
- 影响：内核 allowlist 永远为空

## 10. 文本白名单被 SELinux 拒读
- 现象：`load_allow_list open file failed: -13`
- 处理中：路径迁到 `/data/adb/ksu/`

## 关键日志速查

```
KernelSU: install fd for manager: 10299        # LSM setuid 时给管理器装 fd
KernelSU: [ksu_driver_su] fd installed: 3      # su 会话 fd（我们补的）
KernelSU: do_execveat_common su->ksud!         # su 命中并改写
KernelSU: load_allow_list open file failed: -13 # 白名单文件被 SELinux 拒读
KernelSU: ksu ioctl: cmd=0x... uid=... ret=...  # ioctl 全量日志
KernelSU: ksu: feature req id=...               # 管理器查询的特性号
```
