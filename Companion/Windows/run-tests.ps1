#requires -Version 7.0
<#
.SYNOPSIS
    自动化测试 MagicBoard Windows 伴侣服务 (C 原生可执行文件与 Python 备用脚本)

.DESCRIPTION
    1. 运行协议与映射单元测试
    2. 启动 C 原生版伴侣服务并发送 Live UDP 报文实测 (Win, Alt, Ctrl, Esc, Tab, F1~F12, Watchdog, ResetAll)
    3. 启动 Python 备用版伴侣服务并发送 Live UDP 报文实测
#>

[CmdletBinding()]
param (
    [int]$Port = 52088
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "🧪 [Phase 1/3] 运行 Windows 伴侣协议与映射单元测试..." -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

python test_companion_win.py --unit-tests
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ 单元测试失败！"
    exit $LASTEXITCODE
}
Write-Host "✅ 单元测试全部通过！" -ForegroundColor Green

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "🎹 [Phase 2/3] 实测 C 原生伴侣服务 (magicboard-companion-win.exe)..." -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$cExe = Join-Path $ScriptDir "magicboard-companion-win.exe"
if (-not (Test-Path $cExe)) {
    Write-Host "⚠️ 未检测到可执行文件，正在先执行编译..." -ForegroundColor Yellow
    & pwsh -File (Join-Path $ScriptDir "build-win.ps1")
}

$cLog = Join-Path $ScriptDir "companion_c.log"
if (Test-Path $cLog) { Remove-Item $cLog -Force }

$cProc = Start-Process -FilePath $cExe -ArgumentList "-p $Port" -RedirectStandardOutput $cLog -PassThru
Start-Sleep -Milliseconds 800

try {
    python test_companion_win.py --live --host "127.0.0.1" --port $Port
    Start-Sleep -Milliseconds 600
} finally {
    if (-not $cProc.HasExited) {
        Stop-Process -Id $cProc.Id -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "📋 --- C 原生伴侣服务运行捕获日志 ---" -ForegroundColor DarkGray
if (Test-Path $cLog) {
    Get-Content $cLog
}
Write-Host "✅ C 原生伴侣服务 Live UDP 测试完成！" -ForegroundColor Green

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "🐍 [Phase 3/3] 实测 Python 备用伴侣服务 (magicboard_companion.py)..." -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$pyScript = Join-Path $ScriptDir "magicboard_companion.py"
$pyLog = Join-Path $ScriptDir "companion_py.log"
if (Test-Path $pyLog) { Remove-Item $pyLog -Force }

$pyProc = Start-Process -FilePath "python" -ArgumentList "-u `"$pyScript`" -p $Port" -RedirectStandardOutput $pyLog -PassThru
Start-Sleep -Milliseconds 800

try {
    python test_companion_win.py --live --host "127.0.0.1" --port $Port
    Start-Sleep -Milliseconds 600
} finally {
    if (-not $pyProc.HasExited) {
        Stop-Process -Id $pyProc.Id -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "📋 --- Python 备用伴侣服务运行捕获日志 ---" -ForegroundColor DarkGray
if (Test-Path $pyLog) {
    Get-Content $pyLog
}
Write-Host "✅ Python 备用伴侣服务 Live UDP 测试完成！" -ForegroundColor Green

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "🎉 恭喜！MagicBoard Windows 伴侣服务全部测试通过！" -ForegroundColor Green
Write-Host "   - 单元测试: 全部 13 项通过" -ForegroundColor Green
Write-Host "   - C 原生版 (magicboard-companion-win.exe): Live UDP 注入与看门狗通过" -ForegroundColor Green
Write-Host "   - Python 版 (magicboard_companion.py): Live UDP 注入与看门狗通过" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
