# ============================================================
# 一键装 JADX + 导出 Nova 管理器 APK
# 用法：右键 -> 用 PowerShell 运行（需要联网；APK 导出需 adb）
# ============================================================
$ErrorActionPreference = 'Stop'

Write-Host '===== [1] 下载 JADX（GitHub 最新 Release）=====' -ForegroundColor Cyan
$rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/skylot/jadx/releases/latest' -TimeoutSec 30
$zipUrl = ($rel.assets | Where-Object { $_.name -like 'jadx-*.zip' -and $_.name -notmatch 'sources' } | Select-Object -First 1).browser_download_url
$zipName = Split-Path $zipUrl -Leaf
$dest  = Join-Path $env:USERPROFILE 'Desktop'
$zipPath = Join-Path $dest $zipName

if (-not (Test-Path $zipPath)) {
  Write-Host "  下载 $zipName ..."
  Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -TimeoutSec 300
}
Write-Host "  解压到 $dest\jadx ..."
Expand-Archive -Path $zipPath -DestinationPath (Join-Path $dest 'jadx') -Force
$bin = Join-Path $dest "jadx\bin\jadx.bat"
if (Test-Path $bin) {
  Write-Host "  完成：$bin" -ForegroundColor Green
} else {
  $bin = Get-ChildItem -Path (Join-Path $dest 'jadx') -Recurse -Filter 'jadx.bat' | Select-Object -First 1
  Write-Host "  完成：$($bin.FullName)" -ForegroundColor Green
}

Write-Host '===== [2] 导出管理器 APK =====' -ForegroundColor Cyan
$pm = adb shell pm path com.sukisu.nova 2>$null
if ($pm -match 'package:(\S+)') {
  $apkPath = $Matches[1]
  adb pull $apkPath (Join-Path $dest 'nova-manager.apk') | Out-Null
  Write-Host "  已导出：$dest\nova-manager.apk" -ForegroundColor Green
} else {
  Write-Host '  找不到 com.sukisu.nova（手机没连/没装管理器）' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '反编译命令：' -ForegroundColor Yellow
Write-Host "  $bin $dest\nova-manager.apk"
Write-Host '反编译后重点看：搜 "10003"、"SET_APP_PROFILE"、"App Profile"、"feature"'
