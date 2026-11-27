# ============================================================
# 一键诊断：管理器授权之谜（strace + 10003 遍历 + 日志打包）
# 用法：右键 -> 用 PowerShell 运行（手机需 USB 调试 + root）
# ============================================================
$ErrorActionPreference = 'Continue'
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path $env:USERPROFILE "Desktop\umi-diag-$ts"
New-Item -ItemType Directory -Path $out -Force | Out-Null

Write-Host '===== [0] adb 检查 =====' -ForegroundColor Cyan
adb devices | Out-String
if (-not (adb shell echo ok 2>$null | Select-String -SimpleMatch 'ok')) {
  Write-Host '手机未连接，先在 adb 里授权 USB 调试' -ForegroundColor Red
  exit 1
}

Write-Host '===== [1] 基础信息 =====' -ForegroundColor Cyan
adb shell uname -a                        | Out-File -Encoding utf8 (Join-Path $out 'uname.txt')
adb shell getprop                         | Out-File -Encoding utf8 (Join-Path $out 'props.txt')
adb shell "su -c id"                      | Out-File -Encoding utf8 (Join-Path $out 'su.txt')
adb shell "su -c 'cat /data/adb/ksu/ksu_uids.txt'" 2>$null | Out-File -Encoding utf8 (Join-Path $out 'ksu_uids.txt')
adb shell "su -c 'ls -la /data/adb/ksu/'" | Out-File -Encoding utf8 (Join-Path $out 'ksu_dir.txt')

# ---- 可调参数检查（8o 内核才有） ----
$param = '/sys/module/kernelsu/parameters/ksu_f10003'
$hasParam = adb shell "su -c 'test -f $param && echo YES'" 2>$null | Select-String -SimpleMatch 'YES'
if ($hasParam) {
  Write-Host '===== [2] 10003 数值遍历（每档请重开管理器并点一次授权）=====' -ForegroundColor Cyan
  foreach ($v in '1','2','3','2147483647') {
    adb shell "su -c 'echo $v > $param'" 2>$null | Out-Null
    Write-Host ">>> 已设为 $v ，现在请：重开 SukiSU Nova -> 给应用开授权 -> 回车继续" -ForegroundColor Yellow
    Read-Host '按回车'
    adb shell "su -c dmesg" | Select-String -Pattern 'ksu ioctl|compat feature|feature req|uid list' |
      Out-File -Encoding utf8 (Join-Path $out "dmesg-v$v.txt")
    Write-Host "    已保存 dmesg-v$v.txt（20 秒后自动导出，先手工看也行）"
  }
  adb shell "su -c 'echo 1 > $param'" 2>$null | Out-Null
  Write-Host '已恢复 10003 默认值 1'
} else {
  Write-Host '===== [2] 当前内核没有 8o 参数（ksu_f10003），跳过遍历 =====' -ForegroundColor Yellow
}

# ---- strace 抓管理器 ----
$straced = adb shell "su -c 'which strace'" 2>$null
if ($straced -match 'strace') {
  Write-Host '===== [3] strace 抓管理器 25 秒（期间请去点一次授权）=====' -ForegroundColor Cyan
  adb shell "su -c 'PID=\$(pidof com.sukisu.nova); strace -f -e trace=ioctl,openat,write -p \$PID -o /data/local/tmp/ksu-strace.txt &'"
  Write-Host '>>> 现在去重开管理器并点一次授权，25 秒后自动收' -ForegroundColor Yellow
  Start-Sleep -Seconds 25
  adb shell "su -c 'pkill -f strace'" 2>$null | Out-Null
  adb shell "su -c 'cat /data/local/tmp/ksu-strace.txt'" 2>$null | Out-File -Encoding utf8 (Join-Path $out 'strace.txt')
  Write-Host '    已保存 strace.txt'
} else {
  Write-Host '===== [3] 手机没装 strace，跳过（本机随时可装：adb shell su -c "pm install ..."）=====' -ForegroundColor Yellow
}

# ---- 收尾打包 ----
$ts2 = Get-Date -Format 'yyyyMMdd-HHmmss'
$zip = Join-Path $env:USERPROFILE "Desktop\umi-diag-$ts2.zip"
Compress-Archive -Path (Join-Path $out '*') -DestinationPath $zip -Force
Write-Host ''
Write-Host "完成！把这两个交给开发者：" -ForegroundColor Green
Write-Host "  1) $zip"
Write-Host "  2) 上面的每档 dmesg + strace，里面的 'ksu ioctl: cmd=0x40004b0c' 出现与否是关键"
