# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for rust-server on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for rust-server.
#>

# Windows PowerShell env stub for rust-server

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:RUST_SERVER_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "rust-server") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
