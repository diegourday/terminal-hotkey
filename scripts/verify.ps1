$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class HotkeyVerification {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hwnd, int command);
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hwnd);
    [DllImport("user32.dll")]
    private static extern void keybd_event(byte key, byte scan, uint flags, UIntPtr extra);
    public static void PressAltQ() {
        keybd_event(0x12, 0, 0, UIntPtr.Zero);
        keybd_event(0x51, 0, 0, UIntPtr.Zero);
        keybd_event(0x51, 0, 2, UIntPtr.Zero);
        keybd_event(0x12, 0, 2, UIntPtr.Zero);
    }
    [DllImport("user32.dll")]
    private static extern bool EnumWindows(Callback callback, IntPtr arg);
    private delegate bool Callback(IntPtr hwnd, IntPtr arg);
    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);
    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hwnd);
    public static int TerminalWindows() {
        int count = 0;
        EnumWindows(delegate(IntPtr hwnd, IntPtr arg) {
            uint id; GetWindowThreadProcessId(hwnd, out id);
            try { if (IsWindowVisible(hwnd) && Process.GetProcessById((int)id).ProcessName == "WindowsTerminal") count++; } catch { }
            return true;
        }, IntPtr.Zero);
        return count;
    }
}
'@
$status = Join-Path $env:LOCALAPPDATA 'TerminalHotkey\status.txt'
$content = Get-Content -LiteralPath $status -Raw
if ($content -notmatch 'READY Alt\+Q registered|OPENED Ubuntu|FOCUSED existing Terminal') { throw "Unexpected status: $content" }
$exe = Join-Path $env:LOCALAPPDATA 'TerminalHotkey\TerminalHotkey.exe'
Start-Process -FilePath $exe -WindowStyle Hidden
Start-Sleep -Milliseconds 700
$instances = @(Get-Process -Name TerminalHotkey | Where-Object { $_.Path -eq $exe })
if ($instances.Count -ne 1) { throw 'Single-instance check failed.' }
$before = [HotkeyVerification]::TerminalWindows()
if ($before -eq 0) {
    [HotkeyVerification]::PressAltQ()
    for ($attempt=0; $attempt -lt 20; $attempt++) {
        Start-Sleep -Milliseconds 500
        if ([HotkeyVerification]::TerminalWindows() -gt 0) { break }
    }
    $before = [HotkeyVerification]::TerminalWindows()
    if ($before -ne 1) { throw 'Expected exactly one new Terminal window.' }
    if ((Get-Content -LiteralPath $status -Raw) -notmatch 'OPENED Ubuntu') { throw 'Initial launch failed.' }
    Write-Output 'PASS: Alt+Q opened Ubuntu when no Terminal window existed.'
}
[HotkeyVerification]::PressAltQ()
for ($attempt=0; $attempt -lt 20; $attempt++) {
    Start-Sleep -Milliseconds 500
    if ((Get-Content -LiteralPath $status -Raw) -match 'FOCUSED existing Terminal') { break }
}
$after = [HotkeyVerification]::TerminalWindows()
if ($after -ne $before) { throw 'Alt+Q created a duplicate window.' }
if ((Get-Content -LiteralPath $status -Raw) -notmatch 'FOCUSED existing Terminal') { throw 'Focus check failed.' }
$target = [HotkeyVerification]::GetForegroundWindow()
if ($target -eq [IntPtr]::Zero) { throw 'No foreground window.' }
[HotkeyVerification]::ShowWindowAsync($target, 6) | Out-Null
Start-Sleep -Milliseconds 500
if (![HotkeyVerification]::IsIconic($target)) { throw 'Minimize setup failed.' }
[HotkeyVerification]::PressAltQ()
Start-Sleep -Milliseconds 1000
if ([HotkeyVerification]::IsIconic($target)) { throw 'Terminal was not restored.' }
if ([HotkeyVerification]::GetForegroundWindow() -ne $target) { throw 'Restored terminal is not foreground.' }
if ([HotkeyVerification]::TerminalWindows() -ne $before) { throw 'Restore created a duplicate.' }
$shell = New-Object -ComObject WScript.Shell
$link = Join-Path ([Environment]::GetFolderPath('Startup')) 'Terminal Hotkey.lnk'
if (!(Test-Path -LiteralPath $link)) { throw 'Startup shortcut missing.' }
if ($shell.CreateShortcut($link).TargetPath -ne $exe) { throw 'Startup target mismatch.' }
Write-Output "PASS: Alt+Q focused existing Terminal; minimized Terminal restored; no duplicates; single instance; startup shortcut verified."
