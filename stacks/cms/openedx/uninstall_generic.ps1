# ## Overview
# PowerShell script for uninstall_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic uninstallation script for Open edX.
#>
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }
$EdxDir = Join-Path $LibHome "openedx"
if (Test-Path $EdxDir) {
    Remove-Item -Recurse -Force $EdxDir
}
exit 0
