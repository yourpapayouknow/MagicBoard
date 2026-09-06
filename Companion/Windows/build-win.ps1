#requires -Version 7.0
<#
.SYNOPSIS
    编译 MagicBoard Windows 原生伴侣服务单文件可执行文件

.DESCRIPTION
    使用 MinGW-W64 GCC 编译生成独立的绿色免安装可执行程序 cpwin.exe。
    无额外运行时依赖，链接 ws2_32, user32, shell32。
#>

[CmdletBinding()]
param (
    [string]$Output = "cpwin.exe",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Set-Location $ScriptDir

if ($Clean) {
    if (Test-Path $Output) {
        Remove-Item $Output -Force
        Write-Host "🧹 已清理构建产物: $Output" -ForegroundColor Yellow
    }
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "🔨 正在编译 MagicBoard Windows 原生伴侣服务..." -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# 检查 gcc 是否可用
$gccPath = (Get-Command gcc -ErrorAction SilentlyContinue)?.Source
if (-not $gccPath) {
    Write-Error "❌ 未检测到 gcc.exe，请确保已安装 MinGW-W64 并加入系统 PATH。"
    exit 1
}

Write-Host "✅ 找到编译器: $gccPath" -ForegroundColor Green

$Source = Join-Path $ScriptDir "cpwin.c"
$Target = Join-Path $ScriptDir $Output

$gccArgs = @(
    "-O2",
    "-Wall",
    "-o", $Target,
    $Source,
    "-lws2_32",
    "-luser32",
    "-lshell32"
)

Write-Host "🚀 执行命令: gcc $($gccArgs -join ' ')" -ForegroundColor DarkGray
& gcc @gccArgs

if ($LASTEXITCODE -eq 0 -and (Test-Path $Target)) {
    $fileInfo = Get-Item $Target
    $sizeKb = [Math]::Round($fileInfo.Length / 1024, 2)
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "🎉 编译成功！" -ForegroundColor Green
    Write-Host "   输出文件: $Target" -ForegroundColor Green
    Write-Host "   文件体积: $sizeKb KB (超紧凑绿色原生单文件)" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
} else {
    Write-Error "❌ 编译失败，gcc 退出代码: $LASTEXITCODE"
    exit $LASTEXITCODE
}
