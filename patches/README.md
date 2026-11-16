# 内核侧补丁清单

本仓库不直接放整棵内核树，所有改动以「构建时自动打补丁」的形式放在
`.github/workflows/build.yml` 的第 6 ~ 8n 步里。

| 步骤 | 文件 | 改动 | 原因 |
|---|---|---|---|
| 6 | `build.sh` | 把自带 `curl\|bash setup.sh` 换成 echo | setup 会 `git stash` 掉补丁 |
| 6b | `build.sh` | 删除 AOSP 段（`variant=miui`） | 省一半编译时间 |
| 8 | `fs/read_write.c`、`drivers/input/input.c` | 停用 `#ifdef CONFIG_KSU` 块 | Nova builtin 无 `ksu_handle_sys_read`/`ksu_input_hook` |
| 8b | `include/linux/static_call.h` | 新建空 shim | 4.19 无此头 |
| 8d | `KernelSU/kernel/Makefile`、`preinit.h`、`kpm.c` | `-Wno-error`、宏守卫、`access_ok` 三参数 | 4.19 兼容 |
| 8e | `fs/exec.c` | `if(1)`/`if(0)` 走总入口 | 保证 `ksu_handle_execveat` 总被调用 |
| 8g | `fs/exec.c` | hook 迁到 `do_execveat_common` + su 会话 fd | 覆盖 execveat/posix_spawn |
| 8i | `policy/allowlist.c` | 硬放行 shell(2000)/MT(10302) | dev 保底 |
| 8j | `policy/feature.c` | feature 10003 直接返回支持 | 管理器特性查询 |
| 8k | `supercall/dispatch.c` | ioctl 全量日志 | 诊断 |
| 8l | `supercall/dispatch.c` | allowlist 热加载（1s 限频） | 读列表前重读文件 |
| 8m | `policy/allowlist.c` | 读 `/data/adb/ksu/ksu_uids.txt` 注入 profile | 替代 UI 授权 |
| 8n | `policy/feature.c` | 打印所有 feature 查询 id | 诊断 |

## 想自己复现

直接 fork 本仓库跑 Actions 即可；所有补丁都在 workflow 里，逐条可读。
