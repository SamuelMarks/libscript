# ## Overview
# Automates capturing pixel-perfect screenshots of every step and enumeration
# in the Open edX Windows Installer (.msi) wizard using Vagrant Windows 11 and QEMU screendump.
#
# ## Usage
# powershell devtools/capture_openedx_vagrant_screenshots.ps1

[CmdletBinding()]
param(
    [switch]$Help
)

# ## Show-Help
# Displays usage and help information.
function Show-Help {
    Write-Host "Usage: devtools\capture_openedx_vagrant_screenshots.ps1 [-Help]"
    Write-Host ""
    Write-Host "Automates capturing pixel-perfect screenshots of the Open edX MSI installer"
    Write-Host "running inside the Vagrant Windows 11 guest VM."
    exit 0
}

if ($Help) {
    Show-Help
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$PackagingScreenshotsDir = Join-Path $RepoRoot "packaging\screenshots"
$Cc0ScreenshotsDir = Join-Path $RepoRoot "..\cc0-assets\libscript\openedx\screenshots"
$TempDir = Join-Path $RepoRoot "tests_tmp\vagrant_screenshots"

if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}
if (-not (Test-Path $PackagingScreenshotsDir)) {
    New-Item -ItemType Directory -Path $PackagingScreenshotsDir -Force | Out-Null
}
if (Test-Path (Join-Path $RepoRoot "..\cc0-assets")) {
    if (-not (Test-Path $Cc0ScreenshotsDir)) {
        New-Item -ItemType Directory -Path $Cc0ScreenshotsDir -Force | Out-Null
    }
}

$SshPort = "50661"
$SshKey = Join-Path $env:USERPROFILE ".vagrant.d\insecure_private_key"

# ## Invoke-VmRun
# Helper to execute remote command inside the Vagrant VM via SSH.
function Invoke-VmRun {
    param([string]$Command)
    $fullCmd = @(
        "-p", $SshPort,
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "LogLevel=ERROR",
        "-i", $SshKey,
        "vagrant@127.0.0.1",
        "$Command; exit 0"
    )
    & ssh $fullCmd
}

# ## Invoke-VmScp
# Helper to copy local files to guest VM.
function Invoke-VmScp {
    param(
        [string]$LocalPath,
        [string]$RemotePath
    )
    $cmd = @(
        "-P", $SshPort,
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "LogLevel=ERROR",
        "-i", $SshKey,
        $LocalPath,
        "vagrant@127.0.0.1:$RemotePath"
    )
    & scp $cmd
}

Write-Host "[INFO] Open edX Windows Vagrant screenshot automation initialized."
