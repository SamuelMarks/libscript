# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the Magento e-commerce platform stack.

.DESCRIPTION
Execute this script to install and configure magento on the local system.
#>

$ErrorActionPreference = "Stop"

$MagentoVersion = if ($env:MAGENTO_VERSION) { $env:MAGENTO_VERSION } else { "2.4.6" }
$WwwRoot = if ($env:MAGENTO_WWWROOT) { $env:MAGENTO_WWWROOT } else { "C:\inetpub\wwwroot\magento" }
$DbDriver = if ($env:MAGENTO_DB_DRIVER) { $env:MAGENTO_DB_DRIVER } else { "mariadb" }
$DbName = if ($env:MAGENTO_DB_NAME) { $env:MAGENTO_DB_NAME } else { "magento" }
$DbUser = if ($env:MAGENTO_DB_USER) { $env:MAGENTO_DB_USER } else { "magento" }
$DbPass = if ($env:MAGENTO_DB_PASS) { $env:MAGENTO_DB_PASS } else { "magento" }
$DbHost = if ($env:MAGENTO_DB_HOST) { $env:MAGENTO_DB_HOST } else { "127.0.0.1" }
$ServerName = if ($env:MAGENTO_SERVER_NAME) { $env:MAGENTO_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:MAGENTO_LISTEN) { $env:MAGENTO_LISTEN } else { "80" }
$WebServer = if ($env:MAGENTO_WEBSERVER) { $env:MAGENTO_WEBSERVER } else { "iis" }

if (Test-Path "$WwwRoot\app") {
    Write-Host "[OK] Magento is already installed at $WwwRoot."
    exit 0
}

Write-Host "Installing dependencies for Magento ($WebServer)..."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$libDir = Resolve-Path (Join-Path $scriptDir "..\..\..\_lib")

if ($WebServer -eq "iis") {
    $iisSetup = Join-Path $libDir "web-servers\iis\setup.ps1"
    if (Test-Path $iisSetup) {
        Write-Host "Running IIS Setup..."
        & $iisSetup
    }
}

Write-Host "Downloading Magento ($MagentoVersion)..."
if (-not (Test-Path "$WwwRoot\app")) {
    if (-not (Test-Path $WwwRoot)) {
        New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
    }

    $tmpZip = Join-Path $env:TEMP "magento_$(Get-Random).zip"
    $dlUrl = "https://github.com/magento/magento2/archive/refs/tags/${MagentoVersion}.zip"

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
        
        $inner = Get-ChildItem -Path $WwwRoot -Directory | Where-Object { $_.Name -match "magento" } | Select-Object -First 1
        if ($inner) {
            robocopy.exe "$($inner.FullName)" "$WwwRoot" /E /MOVE /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
            Remove-Item -Path "$($inner.FullName)" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Remove-Item -Path $tmpZip -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Configuring Database ($DbDriver)..."
if ($DbDriver -in @("mariadb", "mysql")) {
    try {
        $mysqlCmd = "CREATE DATABASE IF NOT EXISTS `$DbName`; CREATE USER IF NOT EXISTS '$DbUser'@'$DbHost' IDENTIFIED BY '$DbPass'; GRANT ALL PRIVILEGES ON `$DbName`.* TO '$DbUser'@'$DbHost'; FLUSH PRIVILEGES;"
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
        $env:MAGENTO_PHP_FPM_LISTEN = $phpCgi
    }
}

if ($WebServer -eq "iis") {
    $env:MAGENTO_SERVER_NAME = $ServerName
    $env:LISTEN = $ListenPort
    $env:MAGENTO_WWWROOT = "$WwwRoot\pub"

    $iisCreateServer = Join-Path $libDir "web-servers\iis\create_server_block.ps1"
    if (Test-Path $iisCreateServer) {
        Write-Host "Configuring IIS Block..."
        & $iisCreateServer
    }
}

Write-Host "Magento setup complete on $ServerName (Port $ListenPort)"
exit 0
