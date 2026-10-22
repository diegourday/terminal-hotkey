$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$destination = Join-Path $env:LOCALAPPDATA 'TerminalHotkey'
$exe = Join-Path $destination 'TerminalHotkey.exe'
if (!(Test-Path -LiteralPath (Join-Path $root 'dist\TerminalHotkey.exe'))) { throw 'Build first.' }
$running = @(Get-Process -Name TerminalHotkey -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe })
foreach ($instance in $running) {
    Stop-Process -Id $instance.Id
    if (!$instance.WaitForExit(5000)) { throw 'Terminal Hotkey did not stop.' }
}
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'dist\TerminalHotkey.exe') -Destination $exe -Force
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Startup')) 'Terminal Hotkey.lnk'))
$shortcut.TargetPath = $exe
$shortcut.WorkingDirectory = $destination
$shortcut.Description = 'Alt+Q abre Ubuntu en Windows Terminal'
$shortcut.Save()
Start-Process -FilePath $exe -WorkingDirectory $destination -WindowStyle Hidden
Write-Output "Installed: $exe"
