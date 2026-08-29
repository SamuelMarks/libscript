# ## Overview
# PowerShell script for versioning.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Handles operations related to the component '_common'.

.DESCRIPTION
Execute this script to perform actions for _common.
#>

# versioning.ps1
# Common utilities for managing native libscript installations and version aliases on Windows.

function Get-LibscriptBaseDir {
    if ([string]::IsNullOrEmpty($env:LIBSCRIPT_HOME)) {
        return Join-Path $HOME ".libscript"
    }
    return $env:LIBSCRIPT_HOME
}

function Get-LibscriptVersionDir {
    param (
        [string]$Component,
        [string]$Version
    )
    $BaseDir = Get-LibscriptBaseDir
    return Join-Path $BaseDir "$Component\$Version"
}

function Set-LibscriptAlias {
    param (
        [string]$Component,
        [string]$AliasName,
        [string]$ExactVersion
    )
    
    if ($AliasName -eq $ExactVersion) {
        return
    }

    $LibscriptBase = Get-LibscriptBaseDir
    $BaseDir = Join-Path $LibscriptBase $Component
    if (-not (Test-Path $BaseDir)) {
        New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null
    }
    
    $AliasPath = Join-Path $BaseDir $AliasName
    $ExactPath = Join-Path $BaseDir $ExactVersion
    
    if (Test-Path $AliasPath) {
        Remove-Item -Force -Recurse $AliasPath
    }
    
    # Junctions are used to alias directory paths on Windows without requiring admin privileges
    New-Item -ItemType Junction -Path $AliasPath -Target $ExactPath -Force | Out-Null
}
