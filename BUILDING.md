# 构建说明

## 方式 A：GitHub Actions（推荐）

1. Fork 本仓库
2. `Settings → Actions → General` 允许运行 workflow
3. `Actions → umi-full-nova → Run workflow`，按下面填

| 输入 | 说明 |
|---|---|
| `ksu_ref` | `builtin`（非 GKI 必须）；`v3.0.0` 是 main 树，仅实验用 |
| `hook_mode` | `auto`（builtin）；`off`（main） |
| `hook_patch` | `postexec`（把 hook 移到 do_execveat_common + 装 su 会话 fd） |
| `kprobe_mode` | `off`（builtin）；`on` 仅 main 树 |
| `susfs_mode` | `off`（当前源码树 SUSFS 过旧） |
| `kpm_mode` | `off` 或 `on` |
| `variant` | `miui`（只编 MIUI，快一倍） |
| `kpm_patch` | `0.12.0` |

预计：首次 35–50 分钟；ccache 命中后 15–20 分钟。

## 方式 B：本地 Ubuntu 22.04

```bash
sudo apt install -y build-essential git curl wget bison flex zip unzip bc cpio \
  libssl-dev ccache python-is-python3 python3 libelf-dev device-tree-compiler \
  gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi lz4 zstd xz-utils rsync kmod file

mkdir -p ~/proton-clang && cd ~/proton-clang
wget https://github.com/kdrag0n/proton-clang/archive/refs/tags/20210522.zip
unzip 20210522.zip && cd ~

git clone -b android15-lineage22-mod --depth=1 \
  https://github.com/liyafe1997/kernel_xiaomi_sm8250_mod kernel
cd kernel
# 按 .github/workflows/build.yml 中第 6~8n 步的顺序手工打补丁
bash build.sh umi ksu
```

> 注意：`build.sh` 自带的 KSU setup 会 `git stash` 掉本地补丁，必须先把那行 curl 换成 echo，
> 再由自己先 clone/checkout KSU。

## 产物

- `Kernel_MIUI_umi_*.zip` → TWRP 刷入
- `out/arch/arm64/boot/Image` → 需要自己打 boot.img 时用

## 刷入

```bash
fastboot flash boot boot_stock.img     # 先回官核，清 Magisk ramdisk
# TWRP → Install → Kernel_MIUI_umi_*.zip
```

回滚：`fastboot flash boot boot_stock.img`
