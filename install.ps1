<#
.SYNOPSIS
Global installer for the libscript framework.

.DESCRIPTION
## Overview
Global installer for the libscript framework.

## Usage
Execute this script to install libscript on the local system.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    Write-Host "Usage: install.ps1"
    Write-Host "Bootstraps the LibScript environment."
    exit 0
}

Write-Host "========================================"
Write-Host " LibScript Environment Bootstrap"
Write-Host "========================================"

$LibScriptDir = $PSScriptRoot
Write-Host "To use LibScript, add the following directory to your PATH:"
Write-Host "  $LibScriptDir"
Write-Host ""
Write-Host "Bootstrap complete."
