#!/system/bin/sh
# collect-logs.sh - 在手机端（Termux 或 TWRP）收集排错日志
OUT=/sdcard/umi-logs-$(date +%Y%m%d-%H%M%S)
mkdir -p "$OUT"
dmesg > "$OUT/dmesg.txt" 2>/dev/null
uname -a > "$OUT/uname.txt"
getprop > "$OUT/props.txt"
su -c id > "$OUT/su.txt" 2>/dev/null
su -c 'cat /data/adb/ksu_uids.txt' > "$OUT/ksu_uids.txt" 2>/dev/null
echo "已生成 $OUT"
