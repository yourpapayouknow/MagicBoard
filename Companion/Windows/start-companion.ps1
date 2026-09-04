#requires -Version 7.0
param([int]$Port = 52088)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

# 停止已有的 companion 进程
Get-Process -Name "magicboard-companion-win" -ErrorAction SilentlyContinue | Stop-Process -Force

$exe = Join-Path $ScriptDir "magicboard-companion-win.exe"
$log = Join-Path $ScriptDir "live_c.log"
if (Test-Path $log) { Remove-Item $log -Force }

$psi = [System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $exe
$psi.Arguments = "-p $Port --log `"$log`""
$psi.UseShellExecute = $true
$psi.CreateNoWindow = $true

$proc = [System.Diagnostics.Process]::Start($psi)
Start-Sleep -Milliseconds 600

Write-Host "Companion started (PID: $($proc.Id)) listening on UDP $Port"
