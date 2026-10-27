# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic setup script for MySQL on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }

if ($Action -eq "install") {
    if (Get-Command "mysql" -ErrorAction SilentlyContinue) {
        Write-Host "MySQL is already installed on the system."
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")
        exit 0
    }
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        Write-Host "Installing MySQL via winget..."
        libscript_depends @("Oracle.MySQL")
        exit 0
    }
    if (Get-Command "choco" -ErrorAction SilentlyContinue) {
        Write-Host "Installing MySQL via chocolatey..."
    libscript_depends @(\"mysql\")
        exit 0
    }
    Write-Error "winget or choco is required to install MySQL on Windows."
    exit 1
} elseif ($Action -eq "uninstall") {
    $_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
    . (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")
    libscript_uninstall_pkg -Packages @("Oracle.MySQL", "mysql")
    exit 0
} elseif ($Action -eq "test") {
    & mysql --version
    exit $LASTEXITCODE
}
