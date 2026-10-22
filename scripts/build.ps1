$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
& $compiler /nologo /target:winexe /optimize+ /platform:anycpu /reference:System.Windows.Forms.dll /reference:System.Drawing.dll ("/out:" + (Join-Path $out 'TerminalHotkey.exe')) (Join-Path $root 'src\Program.cs')
if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
Write-Output (Join-Path $out 'TerminalHotkey.exe')
