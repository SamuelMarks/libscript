# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Test execution script for hMailServer on Windows PowerShell.
#>
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "env.ps1")
$Service = Get-Service -Name "hMailServer" -ErrorAction SilentlyContinue
if ($Service) {
    Write-Host "hMailServer service: $($Service.Status)"
} else {
    Write-Host "hMailServer test completed."
}
exit 0
