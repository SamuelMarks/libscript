# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the Joomla CMS stack.

.DESCRIPTION
Execute this script to install and configure joomla on the local system.
#>

$ErrorActionPreference = "Stop"

$JoomlaVersion = if ($env:JOOMLA_VERSION) { $env:JOOMLA_VERSION } else { "5.2.0" }
$WwwRoot = if ($env:JOOMLA_WWWROOT) { $env:JOOMLA_WWWROOT } else { "C:\inetpub\wwwroot\joomla" }
$DbName = if ($env:JOOMLA_DB_NAME) { $env:JOOMLA_DB_NAME } else { "joomla" }
$DbUser = if ($env:JOOMLA_DB_USER) { $env:JOOMLA_DB_USER } else { "joomla" }
$DbPass = if ($env:JOOMLA_DB_PASS) { $env:JOOMLA_DB_PASS } else { "joomla" }
$ServerName = if ($env:JOOMLA_SERVER_NAME) { $env:JOOMLA_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:JOOMLA_LISTEN) { $env:JOOMLA_LISTEN } else { "80" }
$WebServer = if ($env:JOOMLA_WEBSERVER) { $env:JOOMLA_WEBSERVER } else { "iis" }
$DbType = if ($env:JOOMLA_DB_TYPE) { $env:JOOMLA_DB_TYPE } else { "mariadb" }

if ((Test-Path (Join-Path $WwwRoot "configuration.php")) -or (Test-Path (Join-Path $WwwRoot "index.php"))) {
    Write-Host "[OK] Joomla is already installed at $WwwRoot."
    exit 0
}

Write-Host "Installing dependencies for Joomla ($WebServer)..."

if ($WebServer -eq "iis") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $libDir = Resolve-Path (Join-Path $scriptDir "..\..\..\_lib")
    $iisSetup = Join-Path $libDir "web-servers\iis\setup.ps1"
    if (Test-Path $iisSetup) {
        Write-Host "Running IIS Setup..."
        & $iisSetup
    }
}

Write-Host "Downloading Joomla ($JoomlaVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

$tmpZip = Join-Path $env:TEMP "joomla_$(Get-Random).zip"
$dlUrl = "https://github.com/joomla/joomla-cms/releases/download/$JoomlaVersion/Joomla_$JoomlaVersion-Stable-Full_Package.zip"

if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    curl.exe -sSL "$dlUrl" -o "$tmpZip"
} else {
    Invoke-WebRequest -Uri $dlUrl -OutFile $tmpZip -UseBasicParsing
}

if (Test-Path $tmpZip) {
    Expand-Archive -Path $tmpZip -DestinationPath $WwwRoot -Force
    Remove-Item -Path $tmpZip -Force -ErrorAction SilentlyContinue
}

Write-Host "Configuring Database..."
if ($DbType -eq "mariadb" -or $DbType -eq "mysql") {
    try {
        $mysqlCmd = "CREATE DATABASE IF NOT EXISTS `$DbName`; CREATE USER IF NOT EXISTS '$DbUser'@'localhost' IDENTIFIED BY '$DbPass'; GRANT ALL PRIVILEGES ON `$DbName`.* TO '$DbUser'@'localhost'; FLUSH PRIVILEGES;"
        mysql -u root -e $mysqlCmd 2>$null
    } catch {
        Write-Warning "Failed to automatically configure MariaDB. Continuing."
    }
}

# Resolve PHP-CGI executable for IIS
$phpCmd = Get-Command php.exe -ErrorAction SilentlyContinue
if ($phpCmd) {
    $phpExe = $phpCmd.Source
    $phpDir = Split-Path -Parent $phpExe
    $phpCgi = Join-Path $phpDir "php-cgi.exe"
    if (Test-Path $phpCgi) {
        $env:JOOMLA_PHP_FPM_LISTEN = $phpCgi
    }
}

if ($WebServer -eq "iis") {
    $env:JOOMLA_SERVER_NAME = $ServerName
    $env:LISTEN = $ListenPort
    $env:JOOMLA_WWWROOT = $WwwRoot

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $libDir = Resolve-Path (Join-Path $scriptDir "..\..\..\_lib")
    $iisCreateServer = Join-Path $libDir "web-servers\iis\create_server_block.ps1"
    if (Test-Path $iisCreateServer) {
        Write-Host "Configuring IIS Block..."
        & $iisCreateServer
    }
}

Write-Host "Joomla setup complete on $ServerName (Port $ListenPort)"
exit 0
