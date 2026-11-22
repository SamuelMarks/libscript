# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell setup_generic script for Bento Builder stack on Windows.

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

if ($Action -eq "install") {
    Write-Output "Provisioning Bento Builder environment on Windows..."
    
    $LibscriptRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
    
    & (Join-Path $LibscriptRoot "_lib\virtualization\qemu\setup.ps1")
    & (Join-Path $LibscriptRoot "_lib\virtualization\virtualbox\setup.ps1")
    & (Join-Path $LibscriptRoot "_lib\iac\packer\setup.ps1")
    & (Join-Path $LibscriptRoot "_lib\iac\vagrant\setup.ps1")
    
    if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) {
        & (Join-Path $LibscriptRoot "libscript.cmd") install 7zip latest
    }
    Write-Output "Bento Builder environment provisioned on Windows."
}
