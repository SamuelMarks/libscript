# ## Overview
# Automates finding and interacting with Win32 installer controls (buttons, radio buttons, checkboxes, text fields)
# by text or class in Windows GUI sessions with zero external dependencies.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/click_button.ps1 [-TargetFile <path>]

<#
.SYNOPSIS
Searches top-level and child HWNDs to manipulate controls via Win32 messages (BM_CLICK, BM_SETCHECK, WM_SETTEXT).
#>

[CmdletBinding()]
param(
    [string]$TargetFile = "C:/libscript/target_btn.txt"
)

$target = "Next"
if (Test-Path $TargetFile) {
    $target = (Get-Content $TargetFile -Raw).Trim()
}

$code = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

public class Win32Helper {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumChildWindows(IntPtr hWndParent, EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern int GetDlgCtrlID(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam);

    public const uint BM_CLICK = 0x00F5;
    public const uint BM_SETCHECK = 0x00F1;
    public const uint BST_UNCHECKED = 0;
    public const uint BST_CHECKED = 1;
    public const uint WM_SETTEXT = 0x000C;
    public const uint WM_COMMAND = 0x0111;
    public const uint WM_LBUTTONDOWN = 0x0201;
    public const uint WM_LBUTTONUP = 0x0202;
    public const uint BN_CLICKED = 0;

    public static void SafeLog(string msg) {
        try {
            string p = Environment.OSVersion.Platform == PlatformID.Win32NT ? @"C:\libscript\click.log" : "/tmp/libscript_click.log";
            System.IO.File.AppendAllText(p, DateTime.UtcNow.ToString("HH:mm:ss.fff") + " " + msg + Environment.NewLine);
        } catch {}
    }

    public static string NormalizeText(string s) {
        if (string.IsNullOrEmpty(s)) return "";
        StringBuilder sb = new StringBuilder(s.Length);
        for (int i = 0; i < s.Length; i++) {
            char c = s[i];
            if (c == '&' || c == '\r') continue;
            if (c == '\n') { sb.Append(' '); continue; }
            sb.Append(c);
        }
        return sb.ToString().Trim();
    }

    public static bool IsInstallerWindow(IntPtr hWnd) {
        if (!IsWindowVisible(hWnd)) return false;
        StringBuilder sb = new StringBuilder(256);
        GetWindowText(hWnd, sb, 256);
        string s = sb.ToString();

        uint pid = 0;
        GetWindowThreadProcessId(hWnd, out pid);
        string proc = "";
        if (Environment.OSVersion.Platform == PlatformID.Win32NT) {
            try {
                using (Process p = Process.GetProcessById((int)pid)) {
                    if (p != null && p.ProcessName != null) {
                        proc = p.ProcessName;
                    }
                }
            } catch {}
        }

        if (proc.Equals("msiexec", StringComparison.OrdinalIgnoreCase)) return true;
        if (s.IndexOf("Open edX", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Setup", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Installation Mode", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Component Selection", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Destination Folders", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Runtime Environment", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Source Repository", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Network and Credentials", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Database", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Cache", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Ready to Install", StringComparison.OrdinalIgnoreCase) >= 0 ||
            s.IndexOf("Setup Complete", StringComparison.OrdinalIgnoreCase) >= 0) {
            return true;
        }
        return false;
    }

    public static bool ClickControl(string text) {
        IntPtr targetCtrl = IntPtr.Zero;
        IntPtr targetWin = IntPtr.Zero;
        string cleanTarget = NormalizeText(text);

        EnumWindows((hWnd, lParam) => {
            if (!IsInstallerWindow(hWnd)) return true;

            EnumChildWindows(hWnd, (hChild, lChildParam) => {
                if (!IsWindowVisible(hChild)) return true;
                StringBuilder csb = new StringBuilder(256);
                GetWindowText(hChild, csb, 256);
                string cleanCs = NormalizeText(csb.ToString());

                StringBuilder clsb = new StringBuilder(256);
                GetClassName(hChild, clsb, 256);
                string cls = clsb.ToString();

                if (cls.IndexOf("Button", StringComparison.OrdinalIgnoreCase) >= 0 &&
                    cleanCs.IndexOf(cleanTarget, StringComparison.OrdinalIgnoreCase) >= 0) {
                    targetCtrl = hChild;
                    targetWin = hWnd;
                    return false;
                }
                return true;
            }, IntPtr.Zero);

            if (targetCtrl != IntPtr.Zero) return false;
            return true;
        }, IntPtr.Zero);

        if (targetCtrl != IntPtr.Zero) {
            SetForegroundWindow(targetWin);
            SendMessage(targetCtrl, BM_CLICK, IntPtr.Zero, IntPtr.Zero);
            SendMessage(targetCtrl, WM_LBUTTONDOWN, (IntPtr)1, IntPtr.Zero);
            SendMessage(targetCtrl, WM_LBUTTONUP, IntPtr.Zero, IntPtr.Zero);
            int ctrlId = GetDlgCtrlID(targetCtrl);
            SendMessage(targetWin, WM_COMMAND, (IntPtr)((BN_CLICKED << 16) | (ctrlId & 0xFFFF)), targetCtrl);
            SafeLog("Clicked: [" + text + "]");
            return true;
        }
        return false;
    }

    public static bool SelectRadio(string text) {
        IntPtr targetCtrl = IntPtr.Zero;
        IntPtr targetWin = IntPtr.Zero;
        string cleanTarget = NormalizeText(text);

        EnumWindows((hWnd, lParam) => {
            if (!IsInstallerWindow(hWnd)) return true;

            EnumChildWindows(hWnd, (hChild, lChildParam) => {
                if (!IsWindowVisible(hChild)) return true;
                StringBuilder csb = new StringBuilder(256);
                GetWindowText(hChild, csb, 256);
                string cleanCs = NormalizeText(csb.ToString());

                StringBuilder clsb = new StringBuilder(256);
                GetClassName(hChild, clsb, 256);
                string cls = clsb.ToString();

                if (cls.IndexOf("Button", StringComparison.OrdinalIgnoreCase) >= 0 &&
                    cleanCs.IndexOf(cleanTarget, StringComparison.OrdinalIgnoreCase) >= 0) {
                    targetCtrl = hChild;
                    targetWin = hWnd;
                    return false;
                }
                return true;
            }, IntPtr.Zero);

            if (targetCtrl != IntPtr.Zero) return false;
            return true;
        }, IntPtr.Zero);

        if (targetCtrl != IntPtr.Zero) {
            SetForegroundWindow(targetWin);
            SendMessage(targetCtrl, BM_SETCHECK, (IntPtr)BST_CHECKED, IntPtr.Zero);
            SendMessage(targetCtrl, BM_CLICK, IntPtr.Zero, IntPtr.Zero);
            SendMessage(targetCtrl, WM_LBUTTONDOWN, (IntPtr)1, IntPtr.Zero);
            SendMessage(targetCtrl, WM_LBUTTONUP, IntPtr.Zero, IntPtr.Zero);
            int ctrlId = GetDlgCtrlID(targetCtrl);
            SendMessage(targetWin, WM_COMMAND, (IntPtr)((BN_CLICKED << 16) | (ctrlId & 0xFFFF)), targetCtrl);
            SafeLog("Selected Radio: [" + text + "]");
            return true;
        }
        return false;
    }

    public static bool SetCheckbox(string text, bool check) {
        IntPtr targetCtrl = IntPtr.Zero;
        IntPtr targetWin = IntPtr.Zero;
        string cleanTarget = NormalizeText(text);

        EnumWindows((hWnd, lParam) => {
            if (!IsInstallerWindow(hWnd)) return true;

            EnumChildWindows(hWnd, (hChild, lChildParam) => {
                if (!IsWindowVisible(hChild)) return true;
                StringBuilder csb = new StringBuilder(256);
                GetWindowText(hChild, csb, 256);
                string cleanCs = NormalizeText(csb.ToString());

                StringBuilder clsb = new StringBuilder(256);
                GetClassName(hChild, clsb, 256);
                string cls = clsb.ToString();

                if (cls.IndexOf("Button", StringComparison.OrdinalIgnoreCase) >= 0 &&
                    cleanCs.IndexOf(cleanTarget, StringComparison.OrdinalIgnoreCase) >= 0) {
                    targetCtrl = hChild;
                    targetWin = hWnd;
                    return false;
                }
                return true;
            }, IntPtr.Zero);

            if (targetCtrl != IntPtr.Zero) return false;
            return true;
        }, IntPtr.Zero);

        if (targetCtrl != IntPtr.Zero) {
            SetForegroundWindow(targetWin);
            uint val = check ? BST_CHECKED : BST_UNCHECKED;
            SendMessage(targetCtrl, BM_SETCHECK, (IntPtr)val, IntPtr.Zero);
            int ctrlId = GetDlgCtrlID(targetCtrl);
            SendMessage(targetWin, WM_COMMAND, (IntPtr)((BN_CLICKED << 16) | (ctrlId & 0xFFFF)), targetCtrl);
            SafeLog("Checkbox [" + text + "] set to " + check);
            return true;
        }
        return false;
    }

    public static bool FindControl(string text) {
        bool found = false;
        string cleanTarget = NormalizeText(text);
        EnumWindows((hWnd, lParam) => {
            if (!IsInstallerWindow(hWnd)) return true;
            EnumChildWindows(hWnd, (hChild, lChildParam) => {
                if (!IsWindowVisible(hChild)) return true;
                StringBuilder csb = new StringBuilder(256);
                GetWindowText(hChild, csb, 256);
                string cleanCs = NormalizeText(csb.ToString());
                if (cleanCs.IndexOf(cleanTarget, StringComparison.OrdinalIgnoreCase) >= 0) {
                    found = true;
                    return false;
                }
                return true;
            }, IntPtr.Zero);
            if (found) return false;
            return true;
        }, IntPtr.Zero);
        return found;
    }

    public static bool FindDialog(string titlePart) {
        bool found = false;
        string cleanTitle = NormalizeText(titlePart);
        EnumWindows((hWnd, lParam) => {
            if (!IsWindowVisible(hWnd)) return true;
            StringBuilder sb = new StringBuilder(256);
            GetWindowText(hWnd, sb, 256);
            string cleanWin = NormalizeText(sb.ToString());
            if (cleanWin.IndexOf(cleanTitle, StringComparison.OrdinalIgnoreCase) >= 0) {
                found = true;
                return false;
            }
            if (IsInstallerWindow(hWnd)) {
                EnumChildWindows(hWnd, (hChild, lChildParam) => {
                    if (!IsWindowVisible(hChild)) return true;
                    StringBuilder csb = new StringBuilder(256);
                    GetWindowText(hChild, csb, 256);
                    string cleanCs = NormalizeText(csb.ToString());
                    if (cleanCs.IndexOf(cleanTitle, StringComparison.OrdinalIgnoreCase) >= 0) {
                        found = true;
                        return false;
                    }
                    return true;
                }, IntPtr.Zero);
                if (found) return false;
            }
            return true;
        }, IntPtr.Zero);
        return found;
    }

    public static bool SetEditControlText(int editIndex, string newText) {
        int curIdx = 0;
        bool set = false;
        EnumWindows((hWnd, lParam) => {
            if (!IsInstallerWindow(hWnd)) return true;
            EnumChildWindows(hWnd, (hChild, lChildParam) => {
                if (!IsWindowVisible(hChild)) return true;
                StringBuilder clsb = new StringBuilder(256);
                GetClassName(hChild, clsb, 256);
                string cls = clsb.ToString();
                if (cls.IndexOf("Edit", StringComparison.OrdinalIgnoreCase) >= 0) {
                    if (curIdx == editIndex) {
                        SendMessage(hChild, WM_SETTEXT, IntPtr.Zero, newText);
                        set = true;
                        SafeLog("Set Edit[" + editIndex + "] = " + newText);
                        return false;
                    }
                    curIdx++;
                }
                return true;
            }, IntPtr.Zero);
            if (set) return false;
            return true;
        }, IntPtr.Zero);
        return set;
    }
}
'@

Add-Type -TypeDefinition $code -Language CSharp

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$res = $false
$timeoutSec = 5

if ($target.StartsWith("WAIT_DIALOG:")) {
    $title = $target.Substring(12)
    $timeoutSec = 15
    while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
        if ([Win32Helper]::FindDialog($title)) { $res = $true; break }
        Start-Sleep -Milliseconds 400
    }
} elseif ($target.StartsWith("WAIT:")) {
    $btn = $target.Substring(5)
    $timeoutSec = if ($btn -eq "Finish") { 90 } else { 15 }
    while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
        if ([Win32Helper]::FindControl($btn)) { $res = $true; break }
        Start-Sleep -Milliseconds 400
    }
} elseif ($target.StartsWith("RADIO:")) {
    $radio = $target.Substring(6)
    while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
        if ([Win32Helper]::SelectRadio($radio)) { $res = $true; break }
        Start-Sleep -Milliseconds 400
    }
} elseif ($target.StartsWith("CHECK:")) {
    $chk = $target.Substring(6)
    while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
        if ([Win32Helper]::SetCheckbox($chk, $true)) { $res = $true; break }
        Start-Sleep -Milliseconds 400
    }
} elseif ($target.StartsWith("UNCHECK:")) {
    $chk = $target.Substring(8)
    while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
        if ([Win32Helper]::SetCheckbox($chk, $false)) { $res = $true; break }
        Start-Sleep -Milliseconds 400
    }
} elseif ($target.StartsWith("SET_EDIT:")) {
    $parts = $target.Substring(9).Split('|', 2)
    $idx = [int]$parts[0]
    $val = $parts[1]
    while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
        if ([Win32Helper]::SetEditControlText($idx, $val)) { $res = $true; break }
        Start-Sleep -Milliseconds 400
    }
} else {
    $btn = $target
    if ($btn.StartsWith("CLICK:")) { $btn = $target.Substring(6) }
    while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
        if ([Win32Helper]::ClickControl($btn)) { $res = $true; break }
        Start-Sleep -Milliseconds 400
    }
}

Write-Host "Action: $target | Result: $res in $($sw.Elapsed.TotalSeconds)s"
[Win32Helper]::SafeLog("Action: $target | Result: $res in $($sw.Elapsed.TotalSeconds)s")
