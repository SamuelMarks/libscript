# ## Overview
# Ensures Open edX desktop shortcuts exist with proper icons on user desktop and refreshes shell.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/create_desktop_shortcuts.ps1

$desktop = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$iconPath = "C:\libscript\packaging\assets\openedx.ico"

$wsh = New-Object -ComObject WScript.Shell

$s1 = $wsh.CreateShortcut((Join-Path $desktop "Open edX LMS.lnk"))
$s1.TargetPath = "cmd.exe"
$s1.Arguments = '/c call "C:\Program Files\OpenEdX\libscript\stacks\cms\openedx\cli.cmd" lms'
$s1.WorkingDirectory = "C:\Program Files\OpenEdX"
$s1.IconLocation = "$iconPath,0"
$s1.Description = "Open edX Learning Management System"
$s1.Save()

$s2 = $wsh.CreateShortcut((Join-Path $desktop "Open edX Studio.lnk"))
$s2.TargetPath = "cmd.exe"
$s2.Arguments = '/c call "C:\Program Files\OpenEdX\libscript\stacks\cms\openedx\cli.cmd" studio'
$s2.WorkingDirectory = "C:\Program Files\OpenEdX"
$s2.IconLocation = "$iconPath,0"
$s2.Description = "Open edX Studio Course Authoring"
$s2.Save()

$s3 = $wsh.CreateShortcut((Join-Path $desktop "Management CLI.lnk"))
$s3.TargetPath = "cmd.exe"
$s3.Arguments = '/c call "C:\Program Files\OpenEdX\libscript\stacks\cms\openedx\cli.cmd"'
$s3.WorkingDirectory = "C:\Program Files\OpenEdX"
$s3.IconLocation = "$iconPath,0"
$s3.Description = "Open edX Management CLI"
$s3.Save()

$code = @'
using System;
using System.Runtime.InteropServices;
public class ShellNotifier {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
'@
Add-Type -TypeDefinition $code -Language CSharp
[ShellNotifier]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
Write-Host "Desktop shortcuts created and shell notified."
