# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the WordPress CMS stack.

.DESCRIPTION
Execute this script to install and configure wordpress on the local system.
#>

$ErrorActionPreference = "Stop"

function log_info($msg)    { Write-Host "[INFO] $msg" }
function log_warn($msg)    { Write-Warning "$msg" }
function log_error($msg)   { Write-Error "$msg" }
function log_success($msg) { Write-Host "[SUCCESS] $msg" }

function libscript_depends($packages) {
    # Optional dependency tracking for Windows
}

function libscript_download($url, $dest) {
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        curl.exe -sSL "$url" -o "$dest"
    } else {
        Invoke-WebRequest -Uri "$url" -OutFile "$dest" -UseBasicParsing
    }
}

$WordpressVersion = if ($env:WORDPRESS_VERSION) { $env:WORDPRESS_VERSION } else { "latest" }
$WwwRoot = if ($env:WORDPRESS_WWWROOT) { $env:WORDPRESS_WWWROOT } else { "C:\inetpub\wwwroot\wordpress" }
$DbName = if ($env:WORDPRESS_DB_NAME) { $env:WORDPRESS_DB_NAME } else { "wordpress" }
$DbUser = if ($env:WORDPRESS_DB_USER) { $env:WORDPRESS_DB_USER } else { "wordpress" }
$DbPass = if ($env:WORDPRESS_DB_PASS) { $env:WORDPRESS_DB_PASS } else { "wordpress" }
$ServerName = if ($env:WORDPRESS_SERVER_NAME) { $env:WORDPRESS_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:WORDPRESS_LISTEN) { $env:WORDPRESS_LISTEN } else { "80" }
$DbEngine = if ($env:WORDPRESS_DB_ENGINE) { $env:WORDPRESS_DB_ENGINE } else { "sqlite" }
$WebServer = if ($env:WORDPRESS_WEBSERVER) { $env:WORDPRESS_WEBSERVER } else { "iis" }

if (Test-Path (Join-Path $WwwRoot "wp-config.php")) {
    Write-Host "[OK] WordPress already installed and configured at $WwwRoot."
    exit 0
}

log_info "Installing dependencies for WordPress ($WebServer)..."

if ($WebServer -eq "iis") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $libDir = Resolve-Path (Join-Path $scriptDir "..\..\..\_lib")
    $iisSetup = Join-Path $libDir "web-servers\iis\setup.ps1"
    if (Test-Path $iisSetup) {
        Write-Host "Running IIS Setup..."
        & $iisSetup
    }
}

log_info "Downloading WordPress ($WordpressVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

$tmpZip = Join-Path $env:TEMP "wordpress_$(Get-Random).zip"
$tmpExtDir = Join-Path $env:TEMP "wp_extract_$(Get-Random)"
$dlUrl = if ($WordpressVersion -eq "latest") { "https://wordpress.org/latest.zip" } else { "https://wordpress.org/wordpress-$WordpressVersion.zip" }

libscript_download $dlUrl $tmpZip
New-Item -ItemType Directory -Force -Path $tmpExtDir | Out-Null
Expand-Archive -Path $tmpZip -DestinationPath $tmpExtDir -Force
Copy-Item -Path (Join-Path $tmpExtDir "wordpress\*") -Destination $WwwRoot -Recurse -Force
Remove-Item -Path $tmpZip -Force -ErrorAction SilentlyContinue
Remove-Item -Path $tmpExtDir -Recurse -Force -ErrorAction SilentlyContinue

log_info "Configuring Database ($DbEngine)..."
if ($DbEngine -eq "sqlite") {
    $dbFile = Join-Path $WwwRoot "wp-content\db.php"
    if (-not (Test-Path $dbFile)) {
        $muDir = Join-Path $WwwRoot "wp-content\mu-plugins"
        New-Item -ItemType Directory -Force -Path $muDir | Out-Null
        $tmpSqlite = Join-Path $env:TEMP "sqlite-integration.zip"
        $dlSqliteUrl = "https://downloads.wordpress.org/plugin/sqlite-database-integration.zip"
        libscript_download $dlSqliteUrl $tmpSqlite
        Expand-Archive -Path $tmpSqlite -DestinationPath (Join-Path $WwwRoot "wp-content\plugins") -Force
        if (Test-Path (Join-Path $WwwRoot "wp-content\plugins\sqlite-database-integration\db.copy")) {
            Copy-Item -Path (Join-Path $WwwRoot "wp-content\plugins\sqlite-database-integration\db.copy") -Destination $dbFile -Force
        }
        Remove-Item -Path $tmpSqlite -Force -ErrorAction SilentlyContinue
    }
}

$wpConfigSample = Join-Path $WwwRoot "wp-config-sample.php"
$wpConfig = Join-Path $WwwRoot "wp-config.php"

if ((-not (Test-Path $wpConfig)) -and (Test-Path $wpConfigSample)) {
    $content = Get-Content $wpConfigSample
    $content = $content -replace 'database_name_here', $DbName
    $content = $content -replace 'username_here', $DbUser
    $content = $content -replace 'password_here', $DbPass
    Set-Content -Path $wpConfig -Value $content
}

Write-Host "WordPress setup complete on $ServerName (Port $ListenPort)"
exit 0
