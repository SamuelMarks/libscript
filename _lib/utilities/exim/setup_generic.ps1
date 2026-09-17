# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic setup script for Exim on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }
Write-Host "Exim setup on Windows ($Action)."
exit 0
