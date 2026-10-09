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
& (Join-Path $LibscriptRoot "_lib\orchestration\qemu\test.ps1")
& (Join-Path $LibscriptRoot "_lib\orchestration\virtualbox\test.ps1")
& (Join-Path $LibscriptRoot "_lib\orchestration\packer\test.ps1")
& (Join-Path $LibscriptRoot "_lib\orchestration\vagrant\test.ps1")
Write-Output "=== Checks finished ==="
