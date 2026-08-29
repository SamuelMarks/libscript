# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for zig.
#>

$ZigVersion = $env:ZIG_VERSION
if ([string]::IsNullOrEmpty($ZigVersion)) {
    $ZigVersion = "0.12.0"
}
if ($ZigVersion -eq "latest") {
    $ZigVersion = "0.12.0"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$env:PATH = (Join-Path $LibscriptHome "zig\$ZigVersion\bin") + [IO.Path]::PathSeparator + $env:PATH
