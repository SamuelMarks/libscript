# ## Overview
# PowerShell script for uninstall_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic uninstallation script for hMailServer.
#>
if (Get-Command "choco" -ErrorAction SilentlyContinue) { & choco uninstall hmailserver -y }
exit 0
