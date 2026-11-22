# ## Overview
# Configuration management engine for Open edX on Windows (PowerShell).
# Provides get, set, list, generate, and validate operations for environment configurations.
#
# ## Usage
#   .\config.ps1 get <key>
#   .\config.ps1 set <key> <value>
#   .\config.ps1 list
#   .\config.ps1 generate
#   .\config.ps1 validate
#   .\config.ps1 help

<#
.SYNOPSIS
    Configuration management engine for Open edX.
.DESCRIPTION
    Provides get, set, list, generate, and validate operations for LMS and Studio
    configuration files.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$Key,

    [Parameter(Position = 2)]
    [string]$Value
)

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$LibscriptRootDir = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path }

$InstallDir = if ($env:OPENEDX_INSTALL_DIR) {
    $env:OPENEDX_INSTALL_DIR
} elseif ($env:LIBSCRIPT_HOME) {
    Join-Path $env:LIBSCRIPT_HOME "openedx"
} else {
    Join-Path $env:USERPROFILE ".libscript\openedx"
}

$ConfDir = Join-Path $InstallDir "config"
$LmsConf = Join-Path $ConfDir "lms.env.json"
$CmsConf = Join-Path $ConfDir "cms.env.json"
$SchemaFile = Join-Path $ScriptDir "vars.schema.json"
$ConfigHelper = Join-Path $ScriptDir "config_helper.ps1"

# ## Show-Help
# Displays configuration tool usage and options.
function Show-Help {
    Write-Host "Open edX Configuration Management Engine (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\config.ps1 get <key>"
    Write-Host "  .\config.ps1 set <key> <value>"
    Write-Host "  .\config.ps1 list"
    Write-Host "  .\config.ps1 generate"
    Write-Host "  .\config.ps1 validate"
    Write-Host "  .\config.ps1 help"
}

# ## Get-ConfigValue
# Retrieves a configuration value by dot-notated key.
function Get-ConfigValue {
    param([string]$TargetKey)
    if ([string]::IsNullOrEmpty($TargetKey)) {
        Write-Error "Key parameter is required."
        exit 1
    }
    & $ConfigHelper get $LmsConf $TargetKey
}

# ## Set-ConfigValue
# Sets a configuration key-value pair in both LMS and CMS configurations.
function Set-ConfigValue {
    param([string]$TargetKey, [string]$TargetVal)
    if ([string]::IsNullOrEmpty($TargetKey)) {
        Write-Error "Key parameter is required."
        exit 1
    }
    & $ConfigHelper set $LmsConf $CmsConf $TargetKey $TargetVal
}

# ## Show-ConfigList
# Displays the current LMS configuration.
function Show-ConfigList {
    if (Test-Path $LmsConf) {
        Get-Content $LmsConf
    } else {
        Write-Warning "Configuration file not found at $LmsConf."
    }
}

# ## New-Config
# Generates baseline default Open edX configurations.
function New-Config {
    & $ConfigHelper generate $LmsConf $CmsConf
}

# ## Test-Config
# Validates LMS configuration syntax and structure.
function Test-Config {
    & $ConfigHelper validate $LmsConf $SchemaFile
}

switch ($Command.ToLower()) {
    "get"      { Get-ConfigValue -TargetKey $Key }
    "set"      { Set-ConfigValue -TargetKey $Key -TargetVal $Value }
    "list"     { Show-ConfigList }
    "generate" { New-Config }
    "validate" { Test-Config }
    "help"     { Show-Help }
    default    {
        Write-Error "Unknown config command: $Command"
        Show-Help
        exit 1
    }
}
