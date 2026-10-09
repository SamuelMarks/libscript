# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the Nextcloud collaboration platform stack.

.DESCRIPTION
Execute this script to install and configure nextcloud on the local system.
#>

$ErrorActionPreference = "Stop"

$NextcloudVersion = if ($env:NEXTCLOUD_VERSION) { $env:NEXTCLOUD_VERSION } else { "latest" }
$WwwRoot = if ($env:NEXTCLOUD_WWWROOT) { $env:NEXTCLOUD_WWWROOT } else { "C:\inetpub\wwwroot\nextcloud" }
$DbName = if ($env:NEXTCLOUD_DB_NAME) { $env:NEXTCLOUD_DB_NAME } else { "nextcloud" }
$DbUser = if ($env:NEXTCLOUD_DB_USER) { $env:NEXTCLOUD_DB_USER } else { "nextcloud" }
$DbPass = if ($env:NEXTCLOUD_DB_PASS) { $env:NEXTCLOUD_DB_PASS } else { "nextcloud" }
$DbType = if ($env:NEXTCLOUD_DB_TYPE) { $env:NEXTCLOUD_DB_TYPE } else { "sqlite" }
$ServerName = if ($env:NEXTCLOUD_SERVER_NAME) { $env:NEXTCLOUD_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:NEXTCLOUD_LISTEN) { $env:NEXTCLOUD_LISTEN } else { "80" }
$WebServer = if ($env:NEXTCLOUD_WEBSERVER) { $env:NEXTCLOUD_WEBSERVER } else { "iis" }

if ((Test-Path "$WwwRoot\occ") -or (Test-Path "$WwwRoot\version.php")) {
    Write-Host "[OK] Nextcloud is already installed at $WwwRoot."
    exit 0
}

Write-Host "Installing dependencies for Nextcloud ($WebServer)..."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$libDir = Resolve-Path (Join-Path $scriptDir "..\..\..\_lib")

if ($WebServer -eq "iis") {
    $iisSetup = Join-Path $libDir "web-servers\iis\setup.ps1"
    if (Test-Path $iisSetup) {
        Write-Host "Running IIS Setup..."
        & $iisSetup
    }
}

Write-Host "Downloading Nextcloud ($NextcloudVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

$tmpZip = Join-Path $env:TEMP "nextcloud_$(Get-Random).zip"
$dlUrl = if ($NextcloudVersion -eq "latest") { "https://download.nextcloud.com/server/releases/latest.zip" } else { "https://download.nextcloud.com/server/releases/nextcloud-$NextcloudVersion.zip" }

if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    curl.exe -sSL "$dlUrl" -o "$tmpZip"
} else {
    Invoke-WebRequest -Uri $dlUrl -OutFile $tmpZip -UseBasicParsing
}

if (Test-Path $tmpZip) {
    $sevenZip = "C:\Program Files\7-Zip\7z.exe"
    if (Test-Path $sevenZip) {
        & $sevenZip x -y "$tmpZip" "-o$WwwRoot" | Out-Null
    } else {
        Expand-Archive -Path $tmpZip -DestinationPath $WwwRoot -Force
    }

    $inner = Get-ChildItem -Path $WwwRoot -Directory | Where-Object { $_.Name -eq "nextcloud" } | Select-Object -First 1
    if ($inner) {
        robocopy.exe "$($inner.FullName)" "$WwwRoot" /E /MOVE /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
        Remove-Item -Path "$($inner.FullName)" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Path $tmpZip -Force -ErrorAction SilentlyContinue
}

Write-Host "Configuring Database ($DbType)..."

$ncDbType = $DbType
if ($ncDbType -eq "mariadb") { $ncDbType = "mysql" }
elseif ($ncDbType -eq "postgres" -or $ncDbType -eq "postgresql") { $ncDbType = "pgsql" }
elseif ($ncDbType -eq "sqlite") { $ncDbType = "sqlite3" }

$autoconfigPath = Join-Path $WwwRoot "config"
if (-not (Test-Path $autoconfigPath)) { New-Item -ItemType Directory -Force -Path $autoconfigPath | Out-Null }
$autoconfigFile = Join-Path $autoconfigPath "autoconfig.php"
if (-not (Test-Path $autoconfigFile)) {
    $acContent = @"
<?php
`$AUTOCONFIG = array(
  "dbtype"        => "$ncDbType",
  "dbname"        => "$DbName",
  "dbuser"        => "$DbUser",
  "dbpass"        => "$DbPass",
  "dbhost"        => "localhost",
  "dbtableprefix" => "",
);
"@
    Set-Content -Path $autoconfigFile -Value $acContent
}

# Resolve PHP-CGI executable for IIS
$phpCmd = Get-Command php.exe -ErrorAction SilentlyContinue
if ($phpCmd) {
    $phpExe = $phpCmd.Source
    $phpDir = Split-Path -Parent $phpExe
    $phpCgi = Join-Path $phpDir "php-cgi.exe"
    if (Test-Path $phpCgi) {
        $env:NEXTCLOUD_PHP_FPM_LISTEN = $phpCgi
    }
}

if ($WebServer -eq "iis") {
    $env:NEXTCLOUD_SERVER_NAME = $ServerName
    $env:LISTEN = $ListenPort
    $env:NEXTCLOUD_WWWROOT = $WwwRoot

    $iisCreateServer = Join-Path $libDir "web-servers\iis\create_server_block.ps1"
    if (Test-Path $iisCreateServer) {
        Write-Host "Configuring IIS Block..."
        & $iisCreateServer
    }
}

Write-Host "Nextcloud setup complete on $ServerName (Port $ListenPort)"
exit 0
