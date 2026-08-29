# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the pyenv component.
#>

$Version = (Get-Item Env:\PYENV_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\pyenv\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
