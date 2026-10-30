# ## Overview
# Ensures desktop shortcuts exist with proper icons on user desktop and refreshes shell.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/create_desktop_shortcuts.ps1 [-Stack <openedx|wordpress>]

[CmdletBinding()]
param(
    [string]$Stack = "openedx"
)

$desktop = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$wsh = New-Object -ComObject WScript.Shell

$scriptRoot = if ($PSScriptRoot) { (Resolve-Path (Join-Path $PSScriptRoot "..")).Path } else { "C:\libscript" }
$cc0WpAssets = Join-Path $scriptRoot "..\cc0-assets\libscript\wordpress\assets"
$cc0EdxAssets = Join-Path $scriptRoot "..\cc0-assets\libscript\openedx\assets"
$localAssets = if (Test-Path "C:\libscript\packaging\assets") { "C:\libscript\packaging\assets" } else { Join-Path $scriptRoot "packaging\assets" }

if ($Stack -eq "wordpress" -or ($Stack -ne "openedx" -and ((Test-Path "$localAssets\wordpress.ico") -or (Test-Path "$cc0WpAssets\wordpress.ico")) -and -not (Test-Path "$localAssets\openedx.ico"))) {
    $iconPath = if (Test-Path "$cc0WpAssets\wordpress.ico") { "$cc0WpAssets\wordpress.ico" } else { "$localAssets\wordpress.ico" }
    $cliIcon = if (Test-Path "$cc0WpAssets\wordpress_cli.ico") { "$cc0WpAssets\wordpress_cli.ico" } elseif (Test-Path "$localAssets\wordpress_cli.ico") { "$localAssets\wordpress_cli.ico" } else { $iconPath }
    $healthIcon = if (Test-Path "$cc0WpAssets\wordpress_health.ico") { "$cc0WpAssets\wordpress_health.ico" } elseif (Test-Path "$localAssets\wordpress_health.ico") { "$localAssets\wordpress_health.ico" } else { $iconPath }
    $dbIcon = if (Test-Path "$cc0WpAssets\wordpress_db.ico") { "$cc0WpAssets\wordpress_db.ico" } elseif (Test-Path "$localAssets\wordpress_db.ico") { "$localAssets\wordpress_db.ico" } else { $iconPath }
    $bkpIcon = if (Test-Path "$cc0WpAssets\wordpress_backup.ico") { "$cc0WpAssets\wordpress_backup.ico" } elseif (Test-Path "$localAssets\wordpress_backup.ico") { "$localAssets\wordpress_backup.ico" } else { $iconPath }
    $wpDir = "C:\Program Files\WordPress"
    if (-not (Test-Path $wpDir)) { [void](New-Item -ItemType Directory -Path $wpDir -Force) }
    
    $s1 = $wsh.CreateShortcut((Join-Path $desktop "WordPress Management Console.lnk"))
    $s1.TargetPath = "cmd.exe"
    $s1.Arguments = '/c call "C:\Program Files\WordPress\cli.cmd"'
    $s1.WorkingDirectory = $wpDir
    $s1.IconLocation = "$cliIcon,0"
    $s1.Description = "WordPress Administrative Management Console"
    $s1.Save()

    $s2 = $wsh.CreateShortcut((Join-Path $desktop "WordPress Diagnostics & Healthcheck.lnk"))
    $s2.TargetPath = "cmd.exe"
    $s2.Arguments = '/c call "C:\Program Files\WordPress\healthcheck.cmd"'
    $s2.WorkingDirectory = $wpDir
    $s2.IconLocation = "$healthIcon,0"
    $s2.Description = "WordPress Full-Stack Health Diagnostics Probe"
    $s2.Save()

    $s3 = $wsh.CreateShortcut((Join-Path $desktop "WordPress Database Console.lnk"))
    $s3.TargetPath = "cmd.exe"
    $s3.Arguments = '/c call "C:\Program Files\WordPress\dbshell.cmd"'
    $s3.WorkingDirectory = $wpDir
    $s3.IconLocation = "$dbIcon,0"
    $s3.Description = "WordPress Relational Database Interactive Shell"
    $s3.Save()

    $s4 = $wsh.CreateShortcut((Join-Path $desktop "WordPress Backup Utility.lnk"))
    $s4.TargetPath = "cmd.exe"
    $s4.Arguments = '/c call "C:\Program Files\WordPress\backup.cmd"'
    $s4.WorkingDirectory = $wpDir
    $s4.IconLocation = "$bkpIcon,0"
    $s4.Description = "WordPress Backup and Disaster Recovery Utility"
    $s4.Save()
} else {
    $edxDir = "C:\Program Files\OpenEdX"
    if (-not (Test-Path $edxDir) -and (Test-Path "C:\Program Files (x86)\OpenEdX")) {
        $edxDir = "C:\Program Files (x86)\OpenEdX"
    }
    if ((Test-Path "C:\ProgramData\OpenEdX\install_dir.txt")) {
        $cfgInstallDir = (Get-Content -Path "C:\ProgramData\OpenEdX\install_dir.txt" -TotalCount 1 -ErrorAction SilentlyContinue).Trim()
        if ($cfgInstallDir -and (Test-Path $cfgInstallDir)) {
            $edxDir = $cfgInstallDir
        }
    }

    $assetSearchDirs = @(
        $cc0EdxAssets,
        $localAssets,
        (Join-Path $edxDir "libscript\packaging\assets"),
        (Join-Path $edxDir "packaging\assets"),
        (Join-Path $edxDir "assets"),
        "C:\Program Files (x86)\OpenEdX\libscript\packaging\assets",
        "C:\Program Files\OpenEdX\libscript\packaging\assets",
        "C:\OpenEdX\app\libscript\packaging\assets",
        "C:\libscript\packaging\assets"
    )
    # ## Find-AssetIcon
    # Resolves the first existing icon file from the candidate asset directories.
    function Find-AssetIcon([string[]]$FileNames) {
        foreach ($dir in $assetSearchDirs) {
            if (-not $dir) { continue }
            foreach ($fn in $FileNames) {
                $cand = Join-Path $dir $fn
                if (Test-Path $cand) { return $cand }
            }
        }
        return "shell32.dll"
    }
    $iconPath = Find-AssetIcon @("openedx.ico", "AppIcon.ico")
    $lmsIconPath = Find-AssetIcon @("openedx_lms.ico", "LmsIcon.ico", "openedx.ico")
    $cmsIconPath = Find-AssetIcon @("openedx_studio.ico", "openedx_cms.ico", "StudioIcon.ico", "openedx.ico")

    $s1 = $wsh.CreateShortcut((Join-Path $desktop "Open edX LMS.lnk"))
    $s1.TargetPath = "cmd.exe"
    $s1.Arguments = "/c call `"$edxDir\libscript\_lib\web-apps\openedx\cli.cmd`" lms"
    $s1.WorkingDirectory = $edxDir
    $s1.IconLocation = "$lmsIconPath,0"
    $s1.Description = "Open edX Learning Management System"
    $s1.Save()

    $s2 = $wsh.CreateShortcut((Join-Path $desktop "Open edX Studio.lnk"))
    $s2.TargetPath = "cmd.exe"
    $s2.Arguments = "/c call `"$edxDir\libscript\_lib\web-apps\openedx\cli.cmd`" studio"
    $s2.WorkingDirectory = $edxDir
    $s2.IconLocation = "$cmsIconPath,0"
    $s2.Description = "Open edX Studio Course Authoring"
    $s2.Save()

    $s3 = $wsh.CreateShortcut((Join-Path $desktop "Open edX Management Console.lnk"))
    $s3.TargetPath = "cmd.exe"
    $s3.Arguments = "/c call `"$edxDir\libscript\_lib\web-apps\openedx\cli.cmd`""
    $s3.WorkingDirectory = $edxDir
    $s3.IconLocation = "$iconPath,0"
    $s3.Description = "Open edX Management CLI"
    $s3.Save()
}

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
