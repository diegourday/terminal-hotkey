using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

internal static class Program
{
    internal static readonly string DataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "TerminalHotkey");
    internal static void Log(string message) {
        try { Directory.CreateDirectory(DataDir); File.WriteAllText(Path.Combine(DataDir, "status.txt"), DateTime.Now.ToString("s") + " " + message); } catch { }
    }
    [STAThread]
    private static int Main() {
        bool owns;
        using (var mutex = new Mutex(true, @"Local\DiegoUrday.TerminalHotkey", out owns)) {
            if (!owns) return 0;
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            try {
                using (var context = new HotkeyContext()) { Application.Run(context); }
                return 0;
            } catch (Exception ex) {
                Log("ERROR: " + ex.Message);
                MessageBox.Show(ex.Message, "Terminal Hotkey", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 1;
            }
        }
    }
}

internal sealed class HotkeyContext : ApplicationContext
{
    private readonly HotkeyWindow window;
    private readonly System.Windows.Forms.Timer focusTimer;
    private DateTime lastLaunch = DateTime.MinValue;
    private IntPtr lastTerminal = IntPtr.Zero;
    internal HotkeyContext() {
        window = new HotkeyWindow(OpenTerminal);
        if (!window.Register()) {
            window.Dispose();
            throw new InvalidOperationException("Alt+Q ya esta en uso por otra aplicacion. Libera ese atajo y vuelve a abrir Terminal Hotkey.");
        }
        focusTimer = new System.Windows.Forms.Timer { Interval = 100 };
        Program.Log("READY Alt+Q registered");
    }
    private void OpenTerminal() {
        try {
            IntPtr existing = TerminalWindow.IsTerminal(lastTerminal) ? lastTerminal : TerminalWindow.Find();
            if (existing != IntPtr.Zero) {
                FocusTerminal(existing);
                return;
            }
            if ((DateTime.UtcNow - lastLaunch).TotalSeconds < 2) return;
            string terminal = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"Microsoft\WindowsApps\wt.exe");
            if (!File.Exists(terminal)) throw new FileNotFoundException("No se encontro Windows Terminal.");
            Process.Start(new ProcessStartInfo {
                FileName = terminal,
                Arguments = "-w new -p Ubuntu -d \"\\\\wsl$\\Ubuntu\\home\\diegourday\"",
                WorkingDirectory = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                UseShellExecute = true
            });
            lastLaunch = DateTime.UtcNow;
            Program.Log("OPENED Ubuntu");
        } catch (Exception ex) {
            Program.Log("ERROR: " + ex.Message);
            MessageBox.Show(ex.Message, "Terminal Hotkey", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
    private EventHandler focusRetry;
    private void FocusTerminal(IntPtr target) {
        lastTerminal = target;
        focusTimer.Stop();
        if (focusRetry != null) focusTimer.Tick -= focusRetry;
        if (TerminalWindow.IsIconic(target)) TerminalWindow.ShowWindowAsync(target, 9);
        TerminalWindow.SetForegroundWindow(target);
        int attempts = 0;
        focusRetry = delegate {
            if (!TerminalWindow.IsWindow(target)) { focusTimer.Stop(); return; }
            TerminalWindow.SetForegroundWindow(target);
            if (TerminalWindow.GetForegroundWindow() == target) {
                Program.Log("FOCUSED existing Terminal");
                focusTimer.Stop();
            } else if (++attempts >= 5) {
                Program.Log("ERROR: Windows did not allow Terminal focus");
                focusTimer.Stop();
            }
        };
        focusTimer.Tick += focusRetry;
        focusTimer.Start();
    }
    protected override void Dispose(bool disposing) {
        if (disposing) {
            focusTimer.Dispose();
            window.Dispose();
        }
        base.Dispose(disposing);
    }
}

internal static class TerminalWindow
{
    private delegate bool WindowCallback(IntPtr hwnd, IntPtr state);
    [DllImport("user32.dll")]
    private static extern bool EnumWindows(WindowCallback callback, IntPtr state);
    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);
    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")]
    internal static extern bool IsIconic(IntPtr hwnd);
    [DllImport("user32.dll")]
    internal static extern bool IsWindow(IntPtr hwnd);
    [DllImport("user32.dll")]
    internal static extern bool ShowWindowAsync(IntPtr hwnd, int command);
    [DllImport("user32.dll")]
    internal static extern bool SetForegroundWindow(IntPtr hwnd);
    [DllImport("user32.dll")]
    internal static extern IntPtr GetForegroundWindow();
    internal static bool IsTerminal(IntPtr hwnd) {
        if (hwnd == IntPtr.Zero || !IsWindow(hwnd)) return false;
        uint id; GetWindowThreadProcessId(hwnd, out id);
        try {
            using (var process = Process.GetProcessById((int)id)) {
                return process.ProcessName.Equals("WindowsTerminal", StringComparison.OrdinalIgnoreCase);
            }
        } catch (ArgumentException) { return false; } catch (System.ComponentModel.Win32Exception) { return false; }
    }
    internal static IntPtr Find() {
        IntPtr result = IntPtr.Zero;
        EnumWindows(delegate(IntPtr hwnd, IntPtr state) {
            if (!IsWindowVisible(hwnd) && !IsIconic(hwnd)) return true;
            uint id; GetWindowThreadProcessId(hwnd, out id);
            try {
                using (var process = Process.GetProcessById((int)id)) {
                    if (process.ProcessName.Equals("WindowsTerminal", StringComparison.OrdinalIgnoreCase)) {
                        result = hwnd;
                        return false;
                    }
                }
            } catch (ArgumentException) { } catch (System.ComponentModel.Win32Exception) { }
            return true;
        }, IntPtr.Zero);
        return result;
    }
}

internal sealed class HotkeyWindow : NativeWindow, IDisposable
{
    private readonly Action open;
    private bool registered;
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint modifiers, uint key);
    [DllImport("user32.dll")]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    internal HotkeyWindow(Action open) {
        this.open = open;
        CreateHandle(new CreateParams { Caption = "TerminalHotkey.MessageWindow", Parent = new IntPtr(-3) });
    }
    internal bool Register() {
        registered = RegisterHotKey(Handle, 1, 0x0001 | 0x4000, 0x51);
        return registered;
    }
    protected override void WndProc(ref Message m) {
        if (m.Msg == 0x0312 && m.WParam.ToInt32() == 1) open();
        base.WndProc(ref m);
    }
    public void Dispose() {
        if (registered) { UnregisterHotKey(Handle, 1); registered = false; }
        DestroyHandle();
    }
}
