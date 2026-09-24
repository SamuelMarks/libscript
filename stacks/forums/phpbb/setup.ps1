# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the phpBB forum software stack.

.DESCRIPTION
Execute this script to install and configure phpbb on the local system.
#>

$ErrorActionPreference = "Stop"

$PhpbbVersion = if ($env:PHPBB_VERSION) { $env:PHPBB_VERSION } else { "3.3.11" }
$PhpbbMajorVersion = ($PhpbbVersion -split '\.')[0..1] -join '.'
$WwwRoot = if ($env:PHPBB_WWWROOT) { $env:PHPBB_WWWROOT } else { "C:\inetpub\wwwroot\phpbb" }
$DbType = if ($env:PHPBB_DB_TYPE) { $env:PHPBB_DB_TYPE } else { "sqlite" }
$DbName = if ($env:PHPBB_DB_NAME) { $env:PHPBB_DB_NAME } else { "phpbb" }
$DbUser = if ($env:PHPBB_DB_USER) { $env:PHPBB_DB_USER } else { "phpbb" }
$DbPass = if ($env:PHPBB_DB_PASS) { $env:PHPBB_DB_PASS } else { "phpbb" }
$ServerName = if ($env:PHPBB_SERVER_NAME) { $env:PHPBB_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:PHPBB_LISTEN) { $env:PHPBB_LISTEN } else { "80" }
$WebServer = if ($env:PHPBB_WEBSERVER) { $env:PHPBB_WEBSERVER } else { "iis" }

if ((Test-Path "$WwwRoot\config.php") -or (Test-Path "$WwwRoot\phpbb")) {
    Write-Host "[OK] phpBB is already installed at $WwwRoot."
    exit 0
}

Write-Host "Installing dependencies for phpBB ($WebServer)..."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$libDir = Resolve-Path (Join-Path $scriptDir "..\..\..\_lib")

if ($WebServer -eq "iis") {
    $iisSetup = Join-Path $libDir "web-servers\iis\setup.ps1"
    if (Test-Path $iisSetup) {
        Write-Host "Running IIS Setup..."
        & $iisSetup
    }
}

Write-Host "Downloading phpBB ($PhpbbVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

$tmpZip = Join-Path $env:TEMP "phpbb_$(Get-Random).zip"
$dlUrl = "https://download.phpbb.com/pub/release/$PhpbbMajorVersion/$PhpbbVersion/phpBB-$PhpbbVersion.zip"

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

    $inner = Get-ChildItem -Path $WwwRoot -Directory | Where-Object { $_.Name -match "phpBB" } | Select-Object -First 1
    if ($inner) {
        robocopy.exe "$($inner.FullName)" "$WwwRoot" /E /MOVE /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
        Remove-Item -Path "$($inner.FullName)" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Path $tmpZip -Force -ErrorAction SilentlyContinue
}

Write-Host "Configuring Database..."
if ($DbType -eq "sqlite") {
    $sqliteDir = Join-Path $WwwRoot "store"
    if (-not (Test-Path $sqliteDir)) {
        New-Item -ItemType Directory -Force -Path $sqliteDir | Out-Null
    }
}

# Resolve PHP-CGI executable for IIS
$phpCmd = Get-Command php.exe -ErrorAction SilentlyContinue
if ($phpCmd) {
    $phpExe = $phpCmd.Source
    $phpDir = Split-Path -Parent $phpExe
    $phpCgi = Join-Path $phpDir "php-cgi.exe"
    if (Test-Path $phpCgi) {
        $env:PHPBB_PHP_FPM_LISTEN = $phpCgi
    }
}

if ($WebServer -eq "iis") {
    $env:PHPBB_SERVER_NAME = $ServerName
    $env:LISTEN = $ListenPort
    $env:PHPBB_WWWROOT = $WwwRoot

    $iisCreateServer = Join-Path $libDir "web-servers\iis\create_server_block.ps1"
    if (Test-Path $iisCreateServer) {
        Write-Host "Configuring IIS Block..."
        & $iisCreateServer
    }
}

Write-Host "phpBB setup complete on $ServerName (Port $ListenPort)"
exit 0
