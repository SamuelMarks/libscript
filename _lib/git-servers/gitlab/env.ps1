# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for gitlab on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for gitlab.
#>

# Windows PowerShell env stub for gitlab

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:GITLAB_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "gitlab") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
