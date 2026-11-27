# 路线图（接手者版）

> ⛔ 原维护者已停更。以下任务按"接手后可立即开始"排序。

## 第 0 步：复现环境（必做）
- [ ] 跑一次 Actions 编译（31 步 workflow），确认产出 zip
- [ ] 刷机，确认 `adb shell su -c id` = uid=0，root 链路活着
- [ ] 用 `tools/diagnostics.ps1` 出一份诊断包，留作基线

## P0：管理器 UI 授权（两个尾巴之一）⭐ 原维护者指定主攻
> 原维护者不希望以白名单收尾（体验差），UI 授权是最终目标；白名单仅作兜底。
- [ ] 静态：JADX 反编译 `SukiSU_Nova_v3.0.0_30000-release.apk`（Release v0.2.0-archive 有），定位 `10003` 与 `SET_APP_PROFILE` 守卫逻辑
- [ ] 动态：`/sys/module/kernelsu/parameters/ksu_f10003` 遍历 1/2/3/2147483647，每档点一次授权
- [ ] 看 strace：点授权时管理器到底有没有发 ioctl
- [ ] 若缺命令：对照 main 树 uapi/supercall.h 补 handler
- [ ] 若卡签名：放开内核侧签名校验
- 详细过程：docs/FLOW.md 图 2

## P1：文本白名单加载（两个尾巴之二）
- [ ] 验证 8m v2 新路径（`/data/adb/ksu/ksu_uids.txt`）
- [ ] 若仍 EACCES：override_creds / /data/local/tmp / sepolicy 三选一
- 详细过程：docs/FLOW.md 图 3

## P2：可选攻坚
- [ ] 伪造内核版本号，观察 35106/41150 管理器的新协议调用面
- [ ] SUSFS 2.x 移植到 4.19（周级，见 docs/PORTING.md）
- [ ] KPM / CPU 伪装等扩展开关

## P3：工程化收尾
- [ ] 把 workflow 补丁抽成 `patches/*.patch`（git apply 版）
- [ ] 一键打包 boot.img 脚本
- [ ] 硬件 20 项测试清单归档（docs/HARDWARE-TEST.md）
