<#
.SYNOPSIS
Main PowerShell entry point for the libscript framework.

.DESCRIPTION
Execute this script to access global libscript functionality.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    & (Join-Path $PSScriptRoot "libscript.cmd") "--help"
    exit $LASTEXITCODE
}

$LibscriptCmd = Join-Path $PSScriptRoot "libscript.cmd"

if (Test-Path $LibscriptCmd) {
    & $LibscriptCmd @args
} else {
    Write-Error "Could not find libscript.cmd in $PSScriptRoot"
    exit 1
}
