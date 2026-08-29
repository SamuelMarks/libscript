# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for elixir.
#>

$ElixirVersion = $env:ELIXIR_VERSION
if ([string]::IsNullOrEmpty($ElixirVersion)) {
    $ElixirVersion = "1.16.2"
}
if ($ElixirVersion -eq "latest") {
    $ElixirVersion = "1.16.2"
}

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$env:PATH = (Join-Path $LibscriptHome "elixir\$ElixirVersion\bin") + [IO.Path]::PathSeparator + $env:PATH
