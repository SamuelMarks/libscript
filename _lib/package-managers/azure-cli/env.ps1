# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for azure-cli on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for azure-cli.
#>

# Windows PowerShell env stub for azure-cli

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:AZURE_CLI_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "azure-cli") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
