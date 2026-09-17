# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic setup script for hMailServer on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }

if ($Action -eq "install") {
    $Service = Get-Service -Name "hMailServer" -ErrorAction SilentlyContinue
    if ($Service) {
        Write-Host "hMailServer is already installed."
        if ($Service.Status -ne "Running") { Start-Service "hMailServer" }
        exit 0
    }
    if (Get-Command "choco" -ErrorAction SilentlyContinue) {
        Write-Host "Installing hMailServer via chocolatey..."
        & choco install hmailserver -y
        exit 0
    }
    Write-Host "hMailServer requires chocolatey or manual installation."
    exit 0
} elseif ($Action -eq "test") {
    $Service = Get-Service -Name "hMailServer" -ErrorAction SilentlyContinue
    if ($Service) {
        Write-Host "hMailServer service status: $($Service.Status)"
        exit 0
    }
    Write-Host "hMailServer test completed."
    exit 0
} elseif ($Action -eq "uninstall") {
    if (Get-Command "choco" -ErrorAction SilentlyContinue) { & choco uninstall hmailserver -y }
    exit 0
}
