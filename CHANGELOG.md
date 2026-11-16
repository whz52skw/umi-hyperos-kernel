# 更新日志

## v0.1.0 (2026-11-16)

首个可用版本。

### 新增
- 适配 Mi 10 (umi) HyperOS 1.0.7.0 / Android 13 / 内核 4.19.325
- 集成 SukiSU Nova v3.0.0 (30000) `builtin` 树
- GitHub Actions 一键构建（29 步，含全部兼容补丁）
- 文档：STATUS / DIAGNOSIS / ROADMAP / AUTHORIZE / RELEASE NOTES

### 修复
- `static_call.h` 缺失（4.19 shim）
- `KSU_NO_PREINIT` 宏重定义
- `access_ok` 三参数（4.19）
- hook 位置错误导致 `execveat`/`posix_spawn` 漏拦截
- su 会话 fd 在早期启动安装导致卡米

### 已知问题
- 管理器 UI 的「超级用户」写入失败（缺少 `SET_APP_PROFILE` 调用）
- `/data/adb/ksu/.allowlist` 从不生成
- 文本白名单读取被 SELinux 拒绝（`EACCES -13`），路径已迁移待验证
- KPM / SUSFS / CPU 伪装 等扩展功能未启用
