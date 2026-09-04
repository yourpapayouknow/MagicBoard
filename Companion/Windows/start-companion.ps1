#requires -Version 7.0
param([int]$Port = 52088)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

# 停止已有的 companion 进程
Get-Process -Name "magicboard-companion-win" -ErrorAction SilentlyContinue | Stop-Process -Force

$exe = Join-Path $ScriptDir "magicboard-companion-win.exe"
$log = Join-Path $ScriptDir "live_c.log"
if (Test-Path $log) { Remove-Item $log -Force }

$proc = Start-Process -FilePath $exe -ArgumentList "-p $Port" -RedirectStandardOutput $log -PassThru
Start-Sleep -Milliseconds 800

Write-Host "Process ID: $($proc.Id)"
Get-NetUDPEndpoint -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort
