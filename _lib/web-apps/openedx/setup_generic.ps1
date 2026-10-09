# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic setup script for Open edX on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }
Write-Host "Open edX setup action ($Action) on Windows."
exit 0
