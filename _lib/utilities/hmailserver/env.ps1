# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for hMailServer on Windows PowerShell.
#>
if (-not $env:HMAILSERVER_SMTP_PORT) { $env:HMAILSERVER_SMTP_PORT = "25" }
if (-not $env:HMAILSERVER_INSTALL_DIR) { $env:HMAILSERVER_INSTALL_DIR = "${env:ProgramFiles(x86)}\hMailServer" }
$BinPath = Join-Path $env:HMAILSERVER_INSTALL_DIR "Bin"
if (Test-Path $BinPath) {
    $env:PATH = "$BinPath;$env:PATH"
}
