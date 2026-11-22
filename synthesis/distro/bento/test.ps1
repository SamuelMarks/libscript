# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell test script for Bento Builder stack on Windows.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$LibscriptRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
Write-Output "=== Checking Bento Builder components on Windows ==="
& (Join-Path $LibscriptRoot "_lib\virtualization\qemu\test.ps1")
& (Join-Path $LibscriptRoot "_lib\virtualization\virtualbox\test.ps1")
& (Join-Path $LibscriptRoot "_lib\iac\packer\test.ps1")
& (Join-Path $LibscriptRoot "_lib\iac\vagrant\test.ps1")
Write-Output "=== Checks finished ==="
