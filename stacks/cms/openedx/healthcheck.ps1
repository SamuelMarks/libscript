# ## Overview
# Full-stack diagnostic and health probe module for Open edX on Windows (PowerShell).
# Validates MySQL, MongoDB, Redis, Meilisearch, Celery, LMS HTTP, CMS HTTP, and SMTP listeners.
#
# ## Usage
#   .\healthcheck.ps1 [-Json]
#   .\healthcheck.ps1 help

<#
.SYNOPSIS
    Health diagnostics for Open edX.
.DESCRIPTION
    Validates MySQL, MongoDB, Redis, Meilisearch, Celery, LMS HTTP, CMS HTTP, and SMTP listeners.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter()]
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$LmsHost = if ($env:LMS_HOST) { $env:LMS_HOST } else { "127.0.0.1" }
$LmsPort = if ($env:LMS_PORT) { $env:LMS_PORT } else { "8000" }
$CmsHost = if ($env:CMS_HOST) { $env:CMS_HOST } else { "127.0.0.1" }
$CmsPort = if ($env:CMS_PORT) { $env:CMS_PORT } else { "8001" }
$MyHost = if ($env:MYSQL_HOST) { $env:MYSQL_HOST } else { "127.0.0.1" }
$MyPort = if ($env:MYSQL_PORT) { $env:MYSQL_PORT } else { "3306" }
$MgHost = if ($env:MONGODB_HOST) { $env:MONGODB_HOST } else { "127.0.0.1" }
$MgPort = if ($env:MONGODB_PORT) { $env:MONGODB_PORT } else { "27017" }
$RdHost = if ($env:REDIS_HOST) { $env:REDIS_HOST } else { "127.0.0.1" }
$RdPort = if ($env:REDIS_PORT) { $env:REDIS_PORT } else { "6379" }
$MeHost = if ($env:MEILISEARCH_HOST) { $env:MEILISEARCH_HOST } else { "127.0.0.1" }
$MePort = if ($env:MEILISEARCH_PORT) { $env:MEILISEARCH_PORT } else { "7700" }
$SmHost = if ($env:SMTP_HOST) { $env:SMTP_HOST } else { "127.0.0.1" }
$SmPort = if ($env:SMTP_PORT) { $env:SMTP_PORT } else { "25" }

$HealthHelper = Join-Path $ScriptDir "health_helper.ps1"

# ## Show-Help
# Displays usage documentation.
function Show-Help {
    Write-Host "Open edX Healthcheck Diagnostics CLI (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\healthcheck.ps1 [-Json]"
    Write-Host "  .\healthcheck.ps1 help"
}

# ## Invoke-HealthCheck
# Dispatches parameters to the healthcheck helper script.
function Invoke-HealthCheck {
    param([bool]$UseJson)
    $jsonFlag = if ($UseJson) { "1" } else { "0" }
    & $HealthHelper $jsonFlag $LmsHost $LmsPort $CmsHost $CmsPort $MyHost $MyPort $MgHost $MgPort $RdHost $RdPort $MeHost $MePort $SmHost $SmPort
}

if ($Command -in @("help", "--help", "-h")) {
    Show-Help
    exit 0
}

$isJson = $Json.IsPresent -or ($Command -eq "--json")
Invoke-HealthCheck -UseJson $isJson
