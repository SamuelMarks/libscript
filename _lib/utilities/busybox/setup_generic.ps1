# ## Overview
# PowerShell wrapper delegating busybox lifecycle setup to setup_generic.cmd.
#
# ## Usage
# Execute via PowerShell (`ACTION=install|download|ls|ls-remote|use|uninstall`).

<#
.SYNOPSIS
Windows PowerShell setup wrapper for busybox.

.DESCRIPTION
Delegates busybox installation, version resolution, and artifact staging to setup_generic.cmd.
#>

$ErrorActionPreference = "Stop"

$SetupCmd = Join-Path $PSScriptRoot "setup_generic.cmd"
if (Test-Path $SetupCmd) {
    & $SetupCmd @args
    exit $LASTEXITCODE
} else {
    Write-Error "Could not find setup_generic.cmd in $PSScriptRoot"
    exit 1
}
