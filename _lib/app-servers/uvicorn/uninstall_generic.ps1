# ## Overview
# PowerShell script for uninstall_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic uninstallation script for Uvicorn.
#>
if (Get-Command "uv" -ErrorAction SilentlyContinue) { & uv tool uninstall uvicorn }
if (Get-Command "pip" -ErrorAction SilentlyContinue) { & pip uninstall -y uvicorn }
exit 0
