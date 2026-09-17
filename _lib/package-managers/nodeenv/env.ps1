# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for nodeenv on Windows.
.DESCRIPTION
    Appends nodeenv binary directory to the session PATH.
#>
$NodeenvVer = if ($env:NODEENV_VERSION) { $env:NODEENV_VERSION } else { "latest" }
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }

$NodeenvBin = Join-Path $LibHome "nodeenv\$NodeenvVer\Scripts"
if (Test-Path $NodeenvBin) {
    $env:PATH = "$NodeenvBin;$env:PATH"
}
