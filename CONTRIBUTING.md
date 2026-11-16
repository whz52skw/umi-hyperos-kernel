# 贡献指南

感谢你愿意帮忙。这个项目的难点不在于"写出能编过的代码"，而在于**非 GKI 4.19 内核与新版 SukiSU 的协议差异**。

## 最需要的三类贡献

1. **对齐管理器协议**（P0）：让 UI 授权可用，见 [docs/ROADMAP.md](docs/ROADMAP.md)
2. **SUSFS 2.x 移植到 4.19**（P2）
3. **更多设备验证**：同一 SoC（sm8250）的 cmi / cas / lmi / thyme 等

## 提 Issue 之前

- 先看 [docs/FAQ.md](docs/FAQ.md)
- 必须附 `scripts/collect-logs` 生成的日志包（否则无法定位）
- 说明是哪个构建参数组合（ksu_ref / hook_mode / hook_patch / kprobe_mode / susfs_mode / kpm_mode / variant）

## 提 PR 的规范

- 一个 PR 只做一件事
- 改内核代码的，附上"改前/改后 dmesg 对比"
- 改 workflow 的，附一次成功的 Actions 运行链接
- 不要提交任何厂商固件、boot.img、ramdisk、APK

## 本地开发

见 [BUILDING.md](BUILDING.md)。建议流程：

1. Fork → 在 Actions 里跑一次基线构建，确认能出包
2. 改 workflow 里的对应补丁步骤（第 6 ~ 8n 步）
3. 再跑一次，对比产物
4. 刷机验证后提交 PR
