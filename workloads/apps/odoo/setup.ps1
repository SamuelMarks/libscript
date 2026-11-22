# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the Odoo ERP system stack.

.DESCRIPTION
Execute this script to install and configure odoo on the local system.
#>

[CmdletBinding()]
param (
    [switch]$SkipDeps
)

$ErrorActionPreference = "Stop"

if ($env:LIBSCRIPT_SKIP_SYSTEM_DEPS -eq "1") {
    $SkipDeps = $true
}

$OdooVersion = if ($env:ODOO_VERSION) { $env:ODOO_VERSION } else { "17.0" }
$WwwRoot = if ($env:ODOO_WWWROOT) { $env:ODOO_WWWROOT } else { "C:\inetpub\wwwroot\odoo" }
$DbType = if ($env:ODOO_DB_TYPE) { $env:ODOO_DB_TYPE } else { "postgres" }
$DbName = if ($env:ODOO_DB_NAME) { $env:ODOO_DB_NAME } else { "odoo" }
$DbUser = if ($env:ODOO_DB_USER) { $env:ODOO_DB_USER } else { "odoo" }
$DbPass = if ($env:ODOO_DB_PASS) { $env:ODOO_DB_PASS } else { "odoo" }
$DbHost = if ($env:ODOO_DB_HOST) { $env:ODOO_DB_HOST } else { "127.0.0.1" }
$DbPort = if ($env:ODOO_DB_PORT) { $env:ODOO_DB_PORT } else { "5432" }
$ServerName = if ($env:ODOO_SERVER_NAME) { $env:ODOO_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:ODOO_LISTEN) { $env:ODOO_LISTEN } else { "80" }
$OdooPort = if ($env:ODOO_PORT) { $env:ODOO_PORT } else { "8069" }
$WebServer = if ($env:ODOO_WEBSERVER) { $env:ODOO_WEBSERVER } else { "iis" }

Write-Host "Installing dependencies for Odoo ($WebServer)..."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path
$libDir = Join-Path $rootDir "_lib"

if (-not $SkipDeps) {
    if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
        Write-Host "Python not found. Delegating to LibScript python component..."
        & (Join-Path $rootDir "libscript.cmd") install python 3.11
    }

    if ($DbType -eq "postgres" -or $DbType -eq "postgresql") {
        if (-not (Get-Command "psql" -ErrorAction SilentlyContinue)) {
            Write-Host "PostgreSQL not found. Delegating to LibScript postgres component..."
            & (Join-Path $rootDir "libscript.cmd") install postgres latest
        }
    } elseif ($DbType -eq "mariadb" -or $DbType -eq "mysql") {
        if (-not (Get-Command "mysql" -ErrorAction SilentlyContinue)) {
            Write-Host "MariaDB not found. Delegating to LibScript mariadb component..."
            & (Join-Path $rootDir "libscript.cmd") install mariadb latest
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

Write-Host "Downloading Odoo ($OdooVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

$tmpZip = Join-Path $env:TEMP "odoo_$(Get-Random).zip"
$tmpExtDir = Join-Path $env:TEMP "odoo_extract_$(Get-Random)"
$dlUrl = "https://github.com/odoo/odoo/archive/refs/heads/${OdooVersion}.zip"

if (-not (Test-Path (Join-Path $WwwRoot "odoo-bin"))) {
    & (Join-Path $libDir "_common\pkg_mgr.cmd") :libscript_download $dlUrl $tmpZip
    New-Item -ItemType Directory -Force -Path $tmpExtDir | Out-Null
    Expand-Archive -Path $tmpZip -DestinationPath $tmpExtDir -Force
    # github zip extracts into a folder like odoo-17.0
    $extractedFolder = Get-ChildItem -Path $tmpExtDir | Select-Object -First 1
    Copy-Item -Path (Join-Path $extractedFolder.FullName "*") -Destination $WwwRoot -Recurse -Force
    Remove-Item -Path $tmpZip -Force
    Remove-Item -Path $tmpExtDir -Recurse -Force
}

$reqFile = Join-Path $WwwRoot "requirements.txt"
if (Test-Path $reqFile) {
    Write-Host "Installing Python dependencies..."
    try {
        python -m pip install -r $reqFile
    } catch {
        Write-Warning "Failed to install some python dependencies. Continuing anyway..."
    }
}

Write-Host "Configuring Database ($DbType)..."
$provSchema = Join-Path $libDir "databases\provision_schema.cmd"
if ($DbType -eq "postgres" -or $DbType -eq "postgresql") {
    try {
        & $provSchema --engine postgres --host $DbHost --port $DbPort --schema $DbName --user $DbUser --password $DbPass
        psql -U postgres -c "ALTER USER $DbUser CREATEDB;" 2>$null
    } catch {
        Write-Warning "Failed to automatically configure PostgreSQL. You may need to create the database manually."
    }
} elseif ($DbType -eq "mariadb" -or $DbType -eq "mysql") {
    try {
        & $provSchema --engine mysql --host $DbHost --port 3306 --schema $DbName --user $DbUser --password $DbPass
    } catch {
        Write-Warning "Failed to automatically configure MariaDB. You may need to create the database manually."
    }
}

$odooConfig = Join-Path $WwwRoot "odoo.conf"
if (-not (Test-Path $odooConfig)) {
    $confContent = @"
[options]
admin_passwd = admin
db_host = $DbHost
db_port = $DbPort
db_user = $DbUser
db_password = $DbPass
db_name = $DbName
http_port = $OdooPort
proxy_mode = True
addons_path = $WwwRoot\addons
"@
    Set-Content -Path $odooConfig -Value $confContent
}

# In a real environment we'd install a Windows service for Odoo
Write-Host "To run Odoo, execute: cd $WwwRoot ; python odoo-bin -c odoo.conf"

if ($WebServer -eq "iis") {
    $env:ODOO_SERVER_NAME = $ServerName
    $env:LISTEN = $ListenPort
    $env:ODOO_WWWROOT = $WwwRoot
    $env:PROXY_PASS = "http://127.0.0.1:${OdooPort}"
    $env:PROXY_WEBSOCKETS = "1"

    $iisCreateServer = Join-Path $libDir "web-servers\iis\create_server_block.ps1"
    if (Test-Path $iisCreateServer) {
        Write-Host "Configuring IIS Block..."
        & $iisCreateServer
    }
} else {
    Write-Warning "Web server '$WebServer' is not fully automated on Windows by this script. Please configure manually."
}

Write-Host "Odoo setup complete on $ServerName (Port $ListenPort)"
