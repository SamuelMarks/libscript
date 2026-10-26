# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the PrestaShop e-commerce platform stack.

.DESCRIPTION
Execute this script to install and configure prestashop on the local system.
#>

$ErrorActionPreference = "Stop"

$PrestashopVersion = if ($env:PRESTASHOP_VERSION) { $env:PRESTASHOP_VERSION } else { "8.2.4" }
$WwwRoot = if ($env:PRESTASHOP_WWWROOT) { $env:PRESTASHOP_WWWROOT } else { "C:\inetpub\wwwroot\prestashop" }
$DbType = if ($env:PRESTASHOP_DB_TYPE) { $env:PRESTASHOP_DB_TYPE } else { "mariadb" }
$DbName = if ($env:PRESTASHOP_DB_NAME) { $env:PRESTASHOP_DB_NAME } else { "prestashop" }
$DbUser = if ($env:PRESTASHOP_DB_USER) { $env:PRESTASHOP_DB_USER } else { "prestashop" }
$DbPass = if ($env:PRESTASHOP_DB_PASS) { $env:PRESTASHOP_DB_PASS } else { "prestashop" }
$ServerName = if ($env:PRESTASHOP_SERVER_NAME) { $env:PRESTASHOP_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:PRESTASHOP_LISTEN) { $env:PRESTASHOP_LISTEN } else { "80" }
$WebServer = if ($env:PRESTASHOP_WEBSERVER) { $env:PRESTASHOP_WEBSERVER } else { "iis" }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path
$libDir = Join-Path $rootDir "_lib"

Write-Host "Installing dependencies for PrestaShop ($WebServer)..."
if ($env:LIBSCRIPT_SKIP_SYSTEM_DEPS -ne "1") {
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

Write-Host "Downloading PrestaShop ($PrestashopVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

if (-not (Test-Path (Join-Path $WwwRoot "classes")) -and -not (Test-Path (Join-Path $WwwRoot "install"))) {
    $tmpZip = Join-Path $env:TEMP "prestashop_$(Get-Random).zip"
    $tmpExtDir = Join-Path $env:TEMP "ps_extract_$(Get-Random)"
    $dlUrl = "https://github.com/PrestaShop/PrestaShop/releases/download/$PrestashopVersion/prestashop_$PrestashopVersion.zip"

    & (Join-Path $libDir "_common\pkg_mgr.cmd") :libscript_download $dlUrl $tmpZip
    New-Item -ItemType Directory -Force -Path $tmpExtDir | Out-Null
    Expand-Archive -Path $tmpZip -DestinationPath $tmpExtDir -Force
    
    $nestedZip = Join-Path $tmpExtDir "prestashop.zip"
    if (Test-Path $nestedZip) {
        Expand-Archive -Path $nestedZip -DestinationPath $WwwRoot -Force
    } else {
        Copy-Item -Path (Join-Path $tmpExtDir "*") -Destination $WwwRoot -Recurse -Force
    }
    Remove-Item -Path $tmpZip -Force
    Remove-Item -Path $tmpExtDir -Recurse -Force
}

Write-Host "Configuring Database..."
$provSchema = Join-Path $libDir "databases\provision_schema.cmd"
if ($DbType -eq "mariadb" -or $DbType -eq "mysql") {
    try {
        & $provSchema --engine mysql --host 127.0.0.1 --port 3306 --schema $DbName --user $DbUser --password $DbPass
    } catch {
        Write-Warning "Failed to automatically configure MariaDB. You may need to create the database manually."
    }
} elseif ($DbType -eq "postgres" -or $DbType -eq "postgresql") {
    try {
        & $provSchema --engine postgres --host 127.0.0.1 --port 5432 --schema $DbName --user $DbUser --password $DbPass
    } catch {
        Write-Warning "Failed to automatically configure PostgreSQL. You may need to create the database manually."
    }
} elseif ($DbType -eq "sqlite") {
    $sqliteDir = Join-Path $WwwRoot "var\sqlite"
    if (-not (Test-Path $sqliteDir)) {
        New-Item -ItemType Directory -Force -Path $sqliteDir | Out-Null
    }
}

if ($WebServer -eq "iis" -and -not $env:PRESTASHOP_PHP_FPM_LISTEN) {
    $phpExe = (Get-Command php.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
    if ($phpExe) {
        $phpDir = Split-Path -Parent $phpExe
        $phpCgi = Join-Path $phpDir "php-cgi.exe"
        if (Test-Path $phpCgi) {
            $env:PRESTASHOP_PHP_FPM_LISTEN = $phpCgi
        }
    }
}

if ($WebServer -eq "iis") {
    $env:PRESTASHOP_SERVER_NAME = $ServerName
    $env:LISTEN = $ListenPort
    $env:PRESTASHOP_WWWROOT = $WwwRoot

    $iisCreateServer = Join-Path $libDir "web-servers\iis\create_server_block.ps1"
    if (Test-Path $iisCreateServer) {
        Write-Host "Configuring IIS Block..."
        & $iisCreateServer
    }
} else {
    Write-Warning "Web server '$WebServer' is not fully automated on Windows by this script. Please configure manually."
}

Write-Host "PrestaShop setup complete on $ServerName (Port $ListenPort)"
