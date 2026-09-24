# ## Overview
# Automates finding and clicking UI controls (buttons, checkboxes, radio buttons) by text in Windows GUI sessions.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/click_button.ps1

<#
.SYNOPSIS
Searches top-level and child HWNDs to locate and click target controls via BM_CLICK.
#>

$targetFile = 'C:/libscript/target_btn.txt'
$target = "Next"
if (Test-Path $targetFile) {
    $target = (Get-Content $targetFile -Raw).Trim()
}

$code = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

public class Win32Helper {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool EnumChildWindows(IntPtr hWndParent, EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    public const uint BM_CLICK = 0x00F5;

    public static bool ClickControl(string text) {
        IntPtr targetCtrl = IntPtr.Zero;
        IntPtr targetWin = IntPtr.Zero;

        EnumWindows((hWnd, lParam) => {
            StringBuilder sb = new StringBuilder(256);
            GetWindowText(hWnd, sb, 256);
            string s = sb.ToString();

            uint pid = 0;
            GetWindowThreadProcessId(hWnd, out pid);
            string proc = "";
            try { proc = Process.GetProcessById((int)pid).ProcessName; } catch {}

            bool isMsi = proc.Equals("msiexec", StringComparison.OrdinalIgnoreCase);
            bool isTargetWin = isMsi ||
                (s.IndexOf("Open edX", StringComparison.OrdinalIgnoreCase) >= 0 ||
                 s.IndexOf("Setup", StringComparison.OrdinalIgnoreCase) >= 0 ||
                 s.IndexOf("Mode", StringComparison.OrdinalIgnoreCase) >= 0 ||
                 s.IndexOf("Selection", StringComparison.OrdinalIgnoreCase) >= 0 ||
                 s.IndexOf("Folders", StringComparison.OrdinalIgnoreCase) >= 0 ||
                 s.IndexOf("Configuration", StringComparison.OrdinalIgnoreCase) >= 0 ||
                 s.IndexOf("Ready", StringComparison.OrdinalIgnoreCase) >= 0);

            if (isTargetWin) {
                try {
                    System.IO.File.AppendAllText(@"C:\libscript\click.log", "Examining window: [" + s + "] HWND=" + hWnd + " proc=" + proc + Environment.NewLine);
                } catch {}
            }

            EnumChildWindows(hWnd, (hChild, lChildParam) => {
                StringBuilder csb = new StringBuilder(256);
                GetWindowText(hChild, csb, 256);
                string cs = csb.ToString();

                if (isTargetWin && !string.IsNullOrEmpty(cs)) {
                    try {
                        System.IO.File.AppendAllText(@"C:\libscript\click.log", "  child: [" + cs + "] HWND=" + hChild + Environment.NewLine);
                    } catch {}
                }

                if (cs.IndexOf(text, StringComparison.OrdinalIgnoreCase) >= 0) {
                    targetCtrl = hChild;
                    targetWin = hWnd;
                    string msg = "Matched child control [" + cs + "] (HWND " + hChild + ") in window [" + s + "]" + Environment.NewLine;
                    Console.WriteLine(msg);
                    try {
                        System.IO.File.AppendAllText(@"C:\libscript\click.log", msg);
                    } catch {}
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
            string resMsg = "Successfully clicked [" + text + "]" + Environment.NewLine;
            try {
                System.IO.File.AppendAllText(@"C:\libscript\click.log", resMsg);
            } catch {}
            return true;
        }
        string notFound = "Control with text containing [" + text + "] not found" + Environment.NewLine;
        Console.WriteLine(notFound);
        try {
            System.IO.File.AppendAllText(@"C:\libscript\click.log", notFound);
        } catch {}
        return false;
    }
}
"@

Add-Type -TypeDefinition $code -Language CSharp
$res = [Win32Helper]::ClickControl($target)
Write-Host "Target: $target | Click result: $res"
