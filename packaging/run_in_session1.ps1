# ## Overview
# Runs commands interactively within Windows Session 1 (interactive desktop) using explorer.exe token.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/run_in_session1.ps1 -Command "notepad.exe"

param(
    [string]$Command = "msiexec.exe /i C:\libscript\packaging\OpenEdX-Setup.msi"
)

$code = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class SessionRunner {
    [DllImport("advapi32.dll", SetLastError=true)]
    public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

    [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    public static extern bool DuplicateTokenEx(IntPtr hExistingToken, uint dwDesiredAccess, IntPtr lpTokenAttributes, int ImpersonationLevel, int TokenType, out IntPtr phNewToken);

    [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool CreateProcessAsUser(IntPtr hToken, string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CloseHandle(IntPtr hObject);

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct STARTUPINFO {
        public int cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public int dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags;
        public short wShowWindow, cbReserved2;
        public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION {
        public IntPtr hProcess;
        public IntPtr hThread;
        public int dwProcessId;
        public int dwThreadId;
    }

    public static int Run(string cmd) {
        Process[] procs = Process.GetProcessesByName("explorer");
        if (procs.Length == 0) return -1;
        IntPtr hToken;
        // MAXIMUM_ALLOWED | TOKEN_DUPLICATE | TOKEN_ASSIGN_PRIMARY | TOKEN_QUERY
        if (!OpenProcessToken(procs[0].Handle, 0x02000000 | 0x0002 | 0x0001 | 0x0008, out hToken)) return -2;
        IntPtr dupToken;
        if (!DuplicateTokenEx(hToken, 0x02000000, IntPtr.Zero, 2, 1, out dupToken)) {
            CloseHandle(hToken);
            return -3;
        }
        STARTUPINFO si = new STARTUPINFO();
        si.cb = Marshal.SizeOf(si);
        si.lpDesktop = @"winsta0\default";
        PROCESS_INFORMATION pi;
        bool ok = CreateProcessAsUser(dupToken, null, cmd, IntPtr.Zero, IntPtr.Zero, false, 0, IntPtr.Zero, @"C:\libscript", ref si, out pi);
        int err = Marshal.GetLastWin32Error();
        CloseHandle(dupToken);
        CloseHandle(hToken);
        if (ok) {
            CloseHandle(pi.hThread);
            CloseHandle(pi.hProcess);
            return pi.dwProcessId;
        }
        return -err;
    }
}
"@

Add-Type -TypeDefinition $code -Language CSharp
$res = [SessionRunner]::Run($Command)
Write-Host "CreateProcessAsUser Result PID: $res"
