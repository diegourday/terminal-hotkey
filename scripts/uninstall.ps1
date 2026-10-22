$ErrorActionPreference = 'Stop'
$exe = Join-Path $env:LOCALAPPDATA 'TerminalHotkey\TerminalHotkey.exe'
Get-Process -Name TerminalHotkey -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe } | Stop-Process
$link = Join-Path ([Environment]::GetFolderPath('Startup')) 'Terminal Hotkey.lnk'
if (Test-Path -LiteralPath $link) { Remove-Item -LiteralPath $link }
if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe }
Write-Output 'Terminal Hotkey desinstalado.'
