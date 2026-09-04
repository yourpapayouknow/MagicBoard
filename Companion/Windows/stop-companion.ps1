#requires -Version 7.0
Get-Process -Name "magicboard-companion-win" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*magicboard_companion*" } | Stop-Process -Force
Write-Host "Companion processes stopped."
