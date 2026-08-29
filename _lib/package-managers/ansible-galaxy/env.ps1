# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Internal script for ansible-galaxy on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for ansible-galaxy.
#>

# Windows PowerShell env stub for ansible-galaxy

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:ANSIBLE_GALAXY_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "ansible-galaxy") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
