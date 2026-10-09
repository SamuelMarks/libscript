# ## Overview
# User management utility for Open edX on Windows (PowerShell).
# Provides interactive and scriptable administration for Django users (create, set_password, list).
#
# ## Usage
#   .\user.ps1 create <username> <email> [-Password <password>] [-Staff] [-Superuser]
#   .\user.ps1 set_password <username> <password>
#   .\user.ps1 list
#   .\user.ps1 help

<#
.SYNOPSIS
    User management utility for Open edX.
.DESCRIPTION
    Creates accounts, manages passwords, and lists users in Open edX.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$Username,

    [Parameter(Position = 2)]
    [string]$Email,

    [Parameter()]
    [string]$Password,

    [Parameter()]
    [switch]$Staff,

    [Parameter()]
    [switch]$Superuser
)

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$InstallDir = if ($env:OPENEDX_INSTALL_DIR) {
    $env:OPENEDX_INSTALL_DIR
} elseif ($env:LIBSCRIPT_HOME) {
    Join-Path $env:LIBSCRIPT_HOME "openedx"
} else {
    Join-Path $env:USERPROFILE ".libscript\openedx"
}

$UserHelper = Join-Path $ScriptDir "user_helper.ps1"

# ## Show-Help
# Displays user management CLI command usage.
function Show-Help {
    Write-Host "Open edX User Management CLI (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\user.ps1 create <username> <email> [-Password <password>] [-Staff] [-Superuser]"
    Write-Host "  .\user.ps1 set_password <username> <password>"
    Write-Host "  .\user.ps1 list"
    Write-Host "  .\user.ps1 help"
}

# ## Invoke-CreateUser
# Creates a new Open edX user account or updates an existing one.
function Invoke-CreateUser {
    param([string]$TargetUser, [string]$TargetEmail, [string]$Pass, [bool]$IsStaff, [bool]$IsSuper)
    if ([string]::IsNullOrEmpty($TargetUser) -or [string]::IsNullOrEmpty($TargetEmail)) {
        Write-Error "Username and Email are required."
        exit 1
    }
    if ([string]::IsNullOrEmpty($Pass)) {
        $Pass = Read-Host "Enter password for user $TargetUser"
    }
    if ([string]::IsNullOrEmpty($Pass)) {
        Write-Error "Password cannot be empty."
        exit 1
    }
    $staffStr = if ($IsStaff -or $IsSuper) { "True" } else { "False" }
    $superStr = if ($IsSuper) { "True" } else { "False" }
    & $UserHelper create $InstallDir $TargetUser $TargetEmail $Pass $staffStr $superStr
}

# ## Invoke-SetPassword
# Updates password for an existing Open edX user.
function Invoke-SetPassword {
    param([string]$TargetUser, [string]$Pass)
    if ([string]::IsNullOrEmpty($TargetUser) -or [string]::IsNullOrEmpty($Pass)) {
        Write-Error "Username and Password are required."
        exit 1
    }
    & $UserHelper set_password $InstallDir $TargetUser $Pass
}

# ## Invoke-ListUsers
# Displays registered users.
function Invoke-ListUsers {
    & $UserHelper list $InstallDir
}

switch ($Command.ToLower()) {
    "create"       { Invoke-CreateUser -TargetUser $Username -TargetEmail $Email -Pass $Password -IsStaff $Staff.IsPresent -IsSuper $Superuser.IsPresent }
    "set_password" { Invoke-SetPassword -TargetUser $Username -Pass $Email }
    "set-password" { Invoke-SetPassword -TargetUser $Username -Pass $Email }
    "list"         { Invoke-ListUsers }
    "help"         { Show-Help }
    default        {
        Write-Error "Unknown command: $Command"
        Show-Help
        exit 1
    }
}
