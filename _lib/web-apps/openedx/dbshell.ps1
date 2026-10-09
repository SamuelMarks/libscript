# ## Overview
# Database console and query execution wrapper for Open edX on Windows (PowerShell).
# Provides unified CLI access to MySQL, MongoDB, and Redis datastores.
#
# ## Usage
#   .\dbshell.ps1 mysql [optional_mysql_args...]
#   .\dbshell.ps1 mongo [optional_mongo_args...]
#   .\dbshell.ps1 redis [optional_redis_args...]
#   .\dbshell.ps1 query <sql_statement>
#   .\dbshell.ps1 help

<#
.SYNOPSIS
    Database console and query execution wrapper for Open edX.
.DESCRIPTION
    Provides unified CLI access to MySQL, MongoDB, and Redis datastores with configuration discovery.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
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

$MyHost = if ($env:MYSQL_HOST) { $env:MYSQL_HOST } else { "127.0.0.1" }
$MyPort = if ($env:MYSQL_PORT) { $env:MYSQL_PORT } else { "3306" }
$MyUser = if ($env:MYSQL_USER) { $env:MYSQL_USER } else { "openedx" }
$MyDb = if ($env:MYSQL_DATABASE) { $env:MYSQL_DATABASE } else { "openedx" }

$MgHost = if ($env:MONGODB_HOST) { $env:MONGODB_HOST } else { "127.0.0.1" }
$MgPort = if ($env:MONGODB_PORT) { $env:MONGODB_PORT } else { "27017" }
$MgDb = if ($env:MONGODB_DATABASE) { $env:MONGODB_DATABASE } else { "openedx" }

$RdHost = if ($env:REDIS_HOST) { $env:REDIS_HOST } else { "127.0.0.1" }
$RdPort = if ($env:REDIS_PORT) { $env:REDIS_PORT } else { "6379" }

$ConfigJson = Join-Path $InstallDir "config\lms.env.json"
if (Test-Path $ConfigJson) {
    try {
        $raw = Get-Content -Path $ConfigJson -Raw -ErrorAction SilentlyContinue
        $parsed = ConvertFrom-Json $raw -ErrorAction SilentlyContinue
        if ($parsed.DATABASES.default) {
            $def = $parsed.DATABASES.default
            if ($def.HOST) { $MyHost = $def.HOST }
            if ($def.PORT) { $MyPort = [string]$def.PORT }
            if ($def.USER) { $MyUser = $def.USER }
            if ($def.NAME) { $MyDb = $def.NAME }
        }
    } catch {
        # Fall back to defaults
    }
}

# ## Show-Help
# Displays database console command usage.
function Show-Help {
    Write-Host "Open edX Database Console Wrapper (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\dbshell.ps1 mysql [optional_args...]"
    Write-Host "  .\dbshell.ps1 mongo [optional_args...]"
    Write-Host "  .\dbshell.ps1 redis [optional_args...]"
    Write-Host "  .\dbshell.ps1 query <sql_statement>"
    Write-Host "  .\dbshell.ps1 help"
}

# ## Invoke-Mysql
# Launches an interactive MySQL or MariaDB shell.
function Invoke-Mysql {
    param([string[]]$Arguments)
    $bin = Get-Command mysql, mariadb -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bin) {
        Write-Error "Neither mysql nor mariadb executable found in PATH."
        exit 1
    }
    if ($env:MYSQL_PASSWORD) {
        $env:MYSQL_PWD = $env:MYSQL_PASSWORD
    }
    $callArgs = @("-h", $MyHost, "-P", $MyPort, "-u", $MyUser, $MyDb) + $Arguments
    & $bin.Source @callArgs
}

# ## Invoke-Mongo
# Launches an interactive MongoDB shell.
function Invoke-Mongo {
    param([string[]]$Arguments)
    $bin = Get-Command mongosh, mongo -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bin) {
        Write-Error "Neither mongosh nor mongo executable found in PATH."
        exit 1
    }
    $uri = "mongodb://${MgHost}:${MgPort}/${MgDb}"
    $callArgs = @($uri) + $Arguments
    & $bin.Source @callArgs
}

# ## Invoke-Redis
# Launches an interactive Redis CLI shell.
function Invoke-Redis {
    param([string[]]$Arguments)
    $bin = Get-Command redis-cli, valkey-cli -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bin) {
        Write-Error "Neither redis-cli nor valkey-cli executable found in PATH."
        exit 1
    }
    $callArgs = @("-h", $RdHost, "-p", $RdPort) + $Arguments
    & $bin.Source @callArgs
}

# ## Invoke-SqlQuery
# Executes a non-interactive SQL statement against MySQL.
function Invoke-SqlQuery {
    param([string]$Query)
    if ([string]::IsNullOrEmpty($Query)) {
        Write-Error "SQL query is required."
        exit 1
    }
    $bin = Get-Command mysql, mariadb -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bin) {
        Write-Error "No MySQL client available to execute query."
        exit 1
    }
    if ($env:MYSQL_PASSWORD) {
        $env:MYSQL_PWD = $env:MYSQL_PASSWORD
    }
    & $bin.Source -h $MyHost -P $MyPort -u $MyUser -e $Query $MyDb
}

switch ($Command.ToLower()) {
    "mysql"     { Invoke-Mysql -Arguments $ExtraArgs }
    "mongo"     { Invoke-Mongo -Arguments $ExtraArgs }
    "mongodb"   { Invoke-Mongo -Arguments $ExtraArgs }
    "mongosh"   { Invoke-Mongo -Arguments $ExtraArgs }
    "redis"     { Invoke-Redis -Arguments $ExtraArgs }
    "redis-cli" { Invoke-Redis -Arguments $ExtraArgs }
    "query"     { Invoke-SqlQuery -Query ($ExtraArgs -join " ") }
    "sql"       { Invoke-SqlQuery -Query ($ExtraArgs -join " ") }
    "help"      { Show-Help }
    default     {
        Write-Error "Unknown database command: $Command"
        Show-Help
        exit 1
    }
}
