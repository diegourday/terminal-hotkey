# Terminal Hotkey

**Alt+Q** brings Windows Terminal to the foreground, restores it if minimized, or opens Ubuntu if no terminal is running. Runs in the background without a tray icon.

## Download

Download [TerminalHotkey.exe](https://github.com/diegourday/terminal-hotkey/releases/latest), save it in a permanent folder, and run it. To start with Windows, add a shortcut to it in `shell:startup` (open with **Win+R**).

Requires Windows 10/11, Windows Terminal, WSL Ubuntu, and .NET Framework 4.x. Alt+Q must be available.

This build opens Ubuntu in `/home/diegourday`. Change the shortcut, profile, or starting directory in `src/Program.cs` and rebuild for another setup.

## Build and install

From the project folder in WSL, with Node.js and pnpm installed:

```sh
pnpm install
pnpm run build
pnpm run app:install
```

Uses C# and the Windows .NET Framework compiler. Output: `dist/TerminalHotkey.exe`. Installation copies it to `%LOCALAPPDATA%\TerminalHotkey` and enables Windows startup; no administrator privileges needed.

`pnpm run verify` tests focus, restoration, window reuse, single-instance behavior, and startup configuration. Requires the installed app running and leaves Terminal in the foreground.

## Stop or remove

End **TerminalHotkey** in Task Manager to stop it. Run `pnpm run app:uninstall` to remove a scripted installation, or delete the downloaded executable and its Startup shortcut. Diagnostic status remains in `%LOCALAPPDATA%\TerminalHotkey\status.txt`.
