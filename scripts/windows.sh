#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
script="$(wslpath -w "$PWD/scripts/$1.ps1")"
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$script"
