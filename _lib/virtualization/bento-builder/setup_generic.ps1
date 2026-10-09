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
    
    & (Join-Path $LibscriptRoot "_lib\orchestration\qemu\setup.ps1")
    & (Join-Path $LibscriptRoot "_lib\orchestration\virtualbox\setup.ps1")
    & (Join-Path $LibscriptRoot "_lib\orchestration\packer\setup.ps1")
    & (Join-Path $LibscriptRoot "_lib\orchestration\vagrant\setup.ps1")
    
    if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install --silent --force --id=7zip.7zip -e --accept-package-agreements --accept-source-agreements
        }
    }
    Write-Output "Bento Builder environment provisioned on Windows."
}
