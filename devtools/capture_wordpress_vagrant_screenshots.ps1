# ## Overview
# Automates launching WordPress Windows Installer (.msi) wizard inside Vagrant Windows 11,
# stepping through every enumeration (Simple Mode and Advanced Mode flows),
# executing offline and online installation workflows, restoring vanilla VM snapshots,
# and capturing pixel-perfect screenshots of wizard steps, desktop icons, and browser views
# directly from the live QEMU display framebuffer.
#
# ## Usage
# powershell devtools/capture_wordpress_vagrant_screenshots.ps1

[CmdletBinding()]
param(
    [string]$MsiOverride = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$TempDir = Join-Path $RepoRoot "tests_tmp\vagrant_screenshots"
$Cc0ScreenshotsDir = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot "..\cc0-assets\libscript\wordpress\screenshots"))

if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}
if (-not (Test-Path $Cc0ScreenshotsDir)) {
    New-Item -ItemType Directory -Path $Cc0ScreenshotsDir -Force | Out-Null
}

# Discover SSH port
$SshPort = $env:SSH_PORT
if (-not $SshPort) {
    $qemuProc = Get-CimInstance Win32_Process -Filter "Name LIKE 'qemu%'" -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandLine -like "*windows-11*" } | Select-Object -First 1
    if ($qemuProc -and ($qemuProc.CommandLine -match "hostfwd=tcp::(\d+)-:22")) {
        $SshPort = $Matches[1]
    }
}
if (-not $SshPort -and (Get-Command ps -ErrorAction SilentlyContinue)) {
    $psOut = & ps aux 2>$null | Select-String -Pattern "qemu.*windows-11" | Select-Object -First 1
    if ($psOut -match "hostfwd=tcp::(\d+)-:22") {
        $SshPort = $Matches[1]
    }
}
if (-not $SshPort) { $SshPort = "50452" }

$SshKey = Join-Path $env:HOME ".vagrant.d/insecure_private_key"

# Locate QEMU monitor socket
$MonitorSock = $env:MONITOR_SOCK
if (-not $MonitorSock) {
    $sockCandidates = @(
        (Get-ChildItem -Path "$env:HOME/.vagrant.d/tmp/vagrant-qemu" -Filter "qemu_socket" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName),
        "/tmp/qemu_socket_win11"
    )
    foreach ($cand in $sockCandidates) {
        if ($cand -and (Test-Path $cand)) {
            $MonitorSock = $cand
            break
        }
    }
}

Write-Host "[INFO] Using SSH port: $SshPort"
Write-Host "[INFO] QEMU Monitor socket: $MonitorSock"
Write-Host "[INFO] Output directory: $Cc0ScreenshotsDir"

# Delegate to companion POSIX shell runner if available
$shPath = Join-Path $ScriptDir "capture_wordpress_vagrant_screenshots.sh"
if (Test-Path $shPath) {
    & /bin/sh $shPath
    exit $LASTEXITCODE
}
