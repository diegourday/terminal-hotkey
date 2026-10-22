# Terminal Hotkey

Press **Alt+Q** to bring Windows Terminal to the foreground, restoring it if minimized. The app remembers the last window used by the shortcut and finds another if that window closes. If no terminal is open, it launches the Ubuntu profile in `/home/diegourday`, preserving your existing profile appearance.

A single background process listens for the shortcut, with no main window or system tray icon. The installer enables startup with Windows. If Alt+Q is already registered by another app, Terminal Hotkey reports the conflict.

## Requirements

Windows 10/11, Windows Terminal, WSL Ubuntu, and .NET Framework 4.x (included with Windows). Development requires WSL, Node.js, and pnpm. No database, server, or external application packages are required.

## Download and run

Download **TerminalHotkey.exe** from the [latest release](https://github.com/diegourday/terminal-hotkey/releases/latest), save it in a permanent folder, and double-click it. Press **Alt+Q** to open or focus Windows Terminal. Sign in to GitHub with repository access to download this private release.

The executable runs directly; it does not install itself. To start it automatically with Windows, open `shell:startup` from the Run dialog and add a shortcut to your saved executable. Alternatively, use the installation script below.

## Build and install from WSL

```sh
cd /home/diegourday/code/terminal-hotkey
pnpm install
pnpm run build
pnpm run app:install
```

The source stays in WSL. The build uses the Windows .NET Framework compiler and produces `dist/TerminalHotkey.exe`. The installer copies it to `%LOCALAPPDATA%\TerminalHotkey`, creates a Startup shortcut, and starts the app. Administrator privileges are not required.

The `dist/` folder is excluded from Git. Download compiled executables from Releases or rebuild them from the source and scripts in this repository.

## Configuration

The Alt+Q shortcut, Ubuntu profile, and initial directory `/home/diegourday` are defined in `src/Program.cs`. The release is configured for Diego's Ubuntu environment. To change these settings, edit that file, rebuild, and run `pnpm run app:install` to update the installed app.

## Verification

Run `pnpm run verify` with the installed app running. It simulates Alt+Q and checks window reuse, foreground activation, minimized-window restoration, single-instance behavior, and the Startup shortcut target. If no terminal is open, it also checks that Ubuntu opens. The test leaves the terminal in the foreground.

## Stop or uninstall

To stop the app temporarily, end **TerminalHotkey** in Task Manager. To restart an installation made by the script, run `%LOCALAPPDATA%\TerminalHotkey\TerminalHotkey.exe`.

To uninstall an installation made by the script:

```sh
pnpm run app:uninstall
```

This removes the executable and Startup shortcut. Diagnostic status remains in `%LOCALAPPDATA%\TerminalHotkey\status.txt`. If you downloaded the executable directly, stop it and remove the downloaded file and any Startup shortcut you created.

## Implementation

C# with Windows Forms and RegisterHotKey. The app does not capture or log typed text. Holding the shortcut does not trigger repeated launches. When no terminal exists, it launches Windows Terminal with `wt.exe -w new -p Ubuntu -d "\\wsl$\Ubuntu\home\diegourday"`.

References: [RegisterHotKey](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerhotkey), [Windows Terminal CLI](https://learn.microsoft.com/en-us/windows/terminal/command-line-arguments).
