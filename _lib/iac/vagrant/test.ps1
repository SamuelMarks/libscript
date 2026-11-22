# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell test script for Vagrant.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command vagrant -ErrorAction SilentlyContinue) {
    & vagrant --version
    & vagrant plugin list
} else {
    Write-Error "vagrant binary not found in PATH."
    exit 1
}
