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
using System.Runtime.InteropServices;
using System.Text;

public class Win32Helper {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

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

            EnumChildWindows(hWnd, (hChild, lChildParam) => {
                StringBuilder csb = new StringBuilder(256);
                GetWindowText(hChild, csb, 256);
                string cs = csb.ToString();
                if (cs.IndexOf(text, StringComparison.OrdinalIgnoreCase) >= 0) {
                    targetCtrl = hChild;
                    targetWin = hWnd;
                    Console.WriteLine("Matched child control [" + cs + "] (HWND " + hChild + ") in window [" + s + "]");
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
            return true;
        }
        Console.WriteLine("Control with text containing [" + text + "] not found");
        return false;
    }
}
"@

Add-Type -TypeDefinition $code -Language CSharp
$res = [Win32Helper]::ClickControl($target)
Write-Host "Target: $target | Click result: $res"
