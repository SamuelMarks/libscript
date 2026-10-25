# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the Drupal CMS stack.

.DESCRIPTION
Execute this script to install and configure drupal on the local system.
#>

$ErrorActionPreference = "Stop"

$DrupalVersion = if ($env:DRUPAL_VERSION) { $env:DRUPAL_VERSION } else { "10.2.6" }
$WwwRoot = if ($env:DRUPAL_WWWROOT) { $env:DRUPAL_WWWROOT } else { "C:\inetpub\wwwroot\drupal" }
$DbType = if ($env:DRUPAL_DB_TYPE) { $env:DRUPAL_DB_TYPE } else { "sqlite" }
$DbName = if ($env:DRUPAL_DB_NAME) { $env:DRUPAL_DB_NAME } else { "drupal" }
$DbUser = if ($env:DRUPAL_DB_USER) { $env:DRUPAL_DB_USER } else { "drupal" }
$DbPass = if ($env:DRUPAL_DB_PASS) { $env:DRUPAL_DB_PASS } else { "drupal" }
$ServerName = if ($env:DRUPAL_SERVER_NAME) { $env:DRUPAL_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:DRUPAL_LISTEN) { $env:DRUPAL_LISTEN } else { "80" }
$WebServer = if ($env:DRUPAL_WEBSERVER) { $env:DRUPAL_WEBSERVER } else { "iis" }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path
$libDir = Join-Path $rootDir "_lib"

Write-Host "Installing dependencies for Drupal ($WebServer)..."
if (-not (Get-Command "php" -ErrorAction SilentlyContinue)) {
    Write-Host "PHP not found. Delegating to LibScript php component..."
    & (Join-Path $rootDir "libscript.cmd") install php latest
}

if ($DbType -eq "mariadb" -or $DbType -eq "mysql") {
    if (-not (Get-Command "mysql" -ErrorAction SilentlyContinue)) {
        Write-Host "MariaDB not found. Delegating to LibScript mariadb component..."
        & (Join-Path $rootDir "libscript.cmd") install mariadb latest
    }
} elseif ($DbType -eq "postgres" -or $DbType -eq "postgresql") {
    if (-not (Get-Command "psql" -ErrorAction SilentlyContinue)) {
        Write-Host "PostgreSQL not found. Delegating to LibScript postgres component..."
        & (Join-Path $rootDir "libscript.cmd") install postgres latest
    }
}

if ($WebServer -eq "iis") {
    $iisSetup = Join-Path $libDir "web-servers\iis\setup.ps1"
    if (Test-Path $iisSetup) {
        Write-Host "Running IIS Setup..."
        & $iisSetup
    } else {
        Write-Warning "IIS setup script not found at $iisSetup. Assuming IIS is already configured."
    }
}

Write-Host "Downloading Drupal ($DrupalVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

if (-not (Test-Path (Join-Path $WwwRoot "core"))) {
    $tmpZip = Join-Path $env:TEMP "drupal_$(Get-Random).zip"
    $tmpExtDir = Join-Path $env:TEMP "dp_extract_$(Get-Random)"
    $dlUrl = "https://ftp.drupal.org/files/projects/drupal-$DrupalVersion.zip"

    & (Join-Path $libDir "_common\pkg_mgr.cmd") :libscript_download $dlUrl $tmpZip
    New-Item -ItemType Directory -Force -Path $tmpExtDir | Out-Null
    Expand-Archive -Path $tmpZip -DestinationPath $tmpExtDir -Force
    Copy-Item -Path (Join-Path $tmpExtDir "drupal-$DrupalVersion\*") -Destination $WwwRoot -Recurse -Force
    Remove-Item -Path $tmpZip -Force
    Remove-Item -Path $tmpExtDir -Recurse -Force
}

Write-Host "Configuring Database..."
$provSchema = Join-Path $libDir "databases\provision_schema.cmd"
if ($DbType -eq "mariadb" -or $DbType -eq "mysql") {
    & $provSchema --engine mysql --host 127.0.0.1 --port 3306 --schema $DbName --user $DbUser --password $DbPass
} elseif ($DbType -eq "postgres" -or $DbType -eq "postgresql") {
    & $provSchema --engine postgres --host 127.0.0.1 --port 5432 --schema $DbName --user $DbUser --password $DbPass
} elseif ($DbType -eq "sqlite") {
    $sqliteDir = Join-Path $WwwRoot "sites\default\files"
    if (-not (Test-Path $sqliteDir)) {
        New-Item -ItemType Directory -Force -Path $sqliteDir | Out-Null
    }
}

if ($WebServer -eq "iis" -and -not $env:DRUPAL_PHP_FPM_LISTEN) {
    $phpExe = (Get-Command php.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
    if ($phpExe) {
        $phpDir = Split-Path -Parent $phpExe
        $phpCgi = Join-Path $phpDir "php-cgi.exe"
        if (Test-Path $phpCgi) {
            $env:DRUPAL_PHP_FPM_LISTEN = $phpCgi
        }
    }
}

if ($WebServer -eq "iis") {
    $env:DRUPAL_SERVER_NAME = $ServerName
    $env:LISTEN = $ListenPort
    $env:DRUPAL_WWWROOT = $WwwRoot

    $iisCreateServer = Join-Path $libDir "web-servers\iis\create_server_block.ps1"
    if (Test-Path $iisCreateServer) {
        Write-Host "Configuring IIS Block..."
        & $iisCreateServer
    }
} else {
    Write-Warning "Web server '$WebServer' is not fully automated on Windows by this script. Please configure manually."
}

Write-Host "Drupal setup complete on $ServerName (Port $ListenPort)"
