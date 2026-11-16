# collect-logs.ps1 - 一键收集排错日志（Windows）
$ErrorActionPreference = 'Continue'
$out = Join-Path $env:USERPROFILE ('Desktop\umi-logs-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $out -Force | Out-Null

adb shell "su -c 'dmesg'"            | Out-File -Encoding utf8 (Join-Path $out 'dmesg.txt')
adb shell uname -a                    | Out-File -Encoding utf8 (Join-Path $out 'uname.txt')
adb shell getprop                     | Out-File -Encoding utf8 (Join-Path $out 'props.txt')
adb shell "su -c id"                  | Out-File -Encoding utf8 (Join-Path $out 'su.txt')
adb shell "su -c 'cat /data/adb/ksu_uids.txt'" | Out-File -Encoding utf8 (Join-Path $out 'ksu_uids.txt')
adb shell "su -c 'cat /proc/kallsyms | grep -c ksu'" | Out-File -Encoding utf8 (Join-Path $out 'ksu_syms.txt')

Compress-Archive -Path (Join-Path $out '*') -DestinationPath ($out + '.zip') -Force
Write-Host "已生成: $out.zip"
