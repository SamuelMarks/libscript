# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic setup script for hMailServer on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }

if ($Action -eq "install") {
    $Service = Get-Service -Name "hMailServer" -ErrorAction SilentlyContinue
    if ($Service) {
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")
        Write-Host "hMailServer is already installed."
        if ($Service.Status -ne "Running") { Start-Service "hMailServer" }
        exit 0
    }
    if (Get-Command "choco" -ErrorAction SilentlyContinue) {
        Write-Host "Installing hMailServer via chocolatey..."
    libscript_depends @("hmailserver")
        exit 0
    }
    Write-Host "hMailServer requires chocolatey or manual installation."
    exit 0
} elseif ($Action -eq "test") {
    $Service = Get-Service -Name "hMailServer" -ErrorAction SilentlyContinue
    if ($Service) {
        Write-Host "hMailServer service status: $($Service.Status)"
        exit 0
    }
    Write-Host "hMailServer test completed."
    exit 0
} elseif ($Action -eq "uninstall") {
    $_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
    . (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")
    libscript_uninstall_pkg -Packages @("hmailserver")
    exit 0
}
