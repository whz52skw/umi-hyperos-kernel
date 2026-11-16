# publish.ps1 - 一键把本目录发布到 GitHub
# 用法：右键 -> 使用 PowerShell 运行，或在终端执行  .\publish.ps1
$ErrorActionPreference = 'Stop'

$owner = Read-Host 'GitHub 用户名'
$repo  = Read-Host '仓库名（直接回车 = umi-hyperos-kernel）'
if ([string]::IsNullOrWhiteSpace($repo)) { $repo = 'umi-hyperos-kernel' }
$sec   = Read-Host '粘贴 Fine-grained Token（输入不显示）' -AsSecureString
$token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
           [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))

$headers = @{
  Authorization          = "Bearer $token"
  Accept                 = 'application/vnd.github+json'
  'X-GitHub-Api-Version' = '2022-11-28'
  'User-Agent'           = 'umi-kernel-publisher'
}

Write-Host "[1/4] 创建仓库 $owner/$repo ..."
$body = @{
  name        = $repo
  description = 'Xiaomi Mi 10 (umi) HyperOS 1.0 + SukiSU Nova (builtin, 4.19) self-built kernel'
  private     = $false
  has_issues  = $true
} | ConvertTo-Json
try {
  Invoke-RestMethod -Method Post -Uri 'https://api.github.com/user/repos' -Headers $headers -Body $body | Out-Null
  Write-Host '      创建成功'
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 422) { Write-Host '      仓库已存在，继续' }
  else { throw }
}

Write-Host '[2/4] 初始化 git ...'
Set-Location $PSScriptRoot
if (-not (Test-Path .git)) { git init | Out-Null }
git branch -M main | Out-Null
git config user.name  $owner
git config user.email "$owner@users.noreply.github.com"

Write-Host '[3/4] 提交 ...'
git add -A
git -c core.quotepath=false commit -m 'init: Mi 10 umi HyperOS kernel + SukiSU Nova (builtin) work' | Out-Null

Write-Host '[4/4] 推送 ...'
git remote remove origin 2>$null
git remote add origin "https://x-access-token:$token@github.com/$owner/$repo.git"
git push -u origin main --force

git remote set-url origin "https://github.com/$owner/$repo.git"
Write-Host ''
Write-Host "完成：https://github.com/$owner/$repo" -ForegroundColor Green
Write-Host '建议：发布完成后立刻到 GitHub 设置里吊销这个 token。'
