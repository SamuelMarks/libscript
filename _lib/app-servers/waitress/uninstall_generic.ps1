# ## Overview
# PowerShell script for uninstall_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic uninstallation script for Waitress.
#>
if (Get-Command "uv" -ErrorAction SilentlyContinue) { & uv tool uninstall waitress }
if (Get-Command "pip" -ErrorAction SilentlyContinue) { & pip uninstall -y waitress }
exit 0
