# ## Overview
# Captures pixel-perfect screenshots of every step and enumeration in the Open edX
# Windows Installer (.msi) wizard using Vagrant Windows 11 and QEMU screendump.
#
# ## Usage
# powershell devtools/capture_openedx_screenshots.ps1 [OPTIONS]

[CmdletBinding()]
param(
    [switch]$Help
)

# ## Show-Help
# Displays usage and help information.
function Show-Help {
    Write-Host "Usage: devtools\capture_openedx_screenshots.ps1 [-Help]"
    Write-Host ""
    Write-Host "Automates capturing pixel-perfect screenshots of the Open edX MSI installer."
    exit 0
}

if ($Help) {
    Show-Help
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir "capture_openedx_vagrant_screenshots.ps1") @args
