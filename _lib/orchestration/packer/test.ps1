# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell test script for Packer.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command packer -ErrorAction SilentlyContinue) {
    & packer --version
} else {
    Write-Error "packer binary not found in PATH."
    exit 1
}
