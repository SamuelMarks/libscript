$ErrorActionPreference = "Stop"

$NextcloudVersion = if ($env:NEXTCLOUD_VERSION) { $env:NEXTCLOUD_VERSION } else { "latest" }
$WwwRoot = if ($env:WWWROOT) { $env:WWWROOT } else { "C:\inetpub\wwwroot\nextcloud" }
$DbName = if ($env:NEXTCLOUD_DB_NAME) { $env:NEXTCLOUD_DB_NAME } else { "nextcloud" }
$DbUser = if ($env:NEXTCLOUD_DB_USER) { $env:NEXTCLOUD_DB_USER } else { "nextcloud" }
$DbPass = if ($env:NEXTCLOUD_DB_PASS) { $env:NEXTCLOUD_DB_PASS } else { "nextcloud" }
$DbType = if ($env:NEXTCLOUD_DB_TYPE) { $env:NEXTCLOUD_DB_TYPE } else { "sqlite" }
$ServerName = if ($env:NEXTCLOUD_SERVER_NAME) { $env:NEXTCLOUD_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:NEXTCLOUD_LISTEN) { $env:NEXTCLOUD_LISTEN } else { "80" }
$WebServer = if ($env:NEXTCLOUD_WEBSERVER) { $env:NEXTCLOUD_WEBSERVER } else { "iis" }

Write-Host "Installing dependencies for Nextcloud ($WebServer)..."

if (-not (Get-Command "php" -ErrorAction SilentlyContinue)) {
    Write-Host "PHP not found. Attempting to install via Winget..."
    winget install --silent --force --id=PHP.PHP --accept-package-agreements --accept-source-agreements
}

if ($DbType -eq "mariadb" -or $DbType -eq "mysql") {
    if (-not (Get-Command "mysql" -ErrorAction SilentlyContinue)) {
        Write-Host "MariaDB not found. Attempting to install via Winget..."
        winget install --silent --force --id=MariaDB.Server --accept-package-agreements --accept-source-agreements
    }
} elseif ($DbType -eq "postgres" -or $DbType -eq "postgresql") {
    if (-not (Get-Command "psql" -ErrorAction SilentlyContinue)) {
        Write-Host "PostgreSQL not found. Attempting to install via Winget..."
        winget install --silent --force --id=PostgreSQL.PostgreSQL --accept-package-agreements --accept-source-agreements
    }
}

if ($WebServer -eq "iis") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $libDir = Resolve-Path (Join-Path $scriptDir "..\..\..\_lib\")
    $iisSetup = Join-Path $libDir "_server\iis\setup_win.ps1"
    if (Test-Path $iisSetup) {
        Write-Host "Running IIS Setup..."
        & $iisSetup
    } else {
        Write-Warning "IIS setup script not found at $iisSetup. Assuming IIS is already configured."
    }
}

Write-Host "Downloading Nextcloud ($NextcloudVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

$tmpZip = Join-Path $env:TEMP "nextcloud_$(Get-Random).zip"
$tmpExtDir = Join-Path $env:TEMP "nc_extract_$(Get-Random)"
$dlUrl = if ($NextcloudVersion -eq "latest") { "https://download.nextcloud.com/server/releases/latest.zip" } else { "https://download.nextcloud.com/server/releases/nextcloud-$NextcloudVersion.zip" }

Invoke-WebRequest -Uri $dlUrl -OutFile $tmpZip
New-Item -ItemType Directory -Force -Path $tmpExtDir | Out-Null
Expand-Archive -Path $tmpZip -DestinationPath $tmpExtDir -Force
Copy-Item -Path (Join-Path $tmpExtDir "nextcloud\*") -Destination $WwwRoot -Recurse -Force
Remove-Item -Path $tmpZip -Force
Remove-Item -Path $tmpExtDir -Recurse -Force

Write-Host "Configuring Database ($DbType)..."

if ($DbType -eq "mariadb" -or $DbType -eq "mysql") {
    try {
        $mysqlCmd = "CREATE DATABASE IF NOT EXISTS `$DbName`; CREATE USER IF NOT EXISTS '$DbUser'@'localhost' IDENTIFIED BY '$DbPass'; GRANT ALL PRIVILEGES ON `$DbName`.* TO '$DbUser'@'localhost'; FLUSH PRIVILEGES;"
        mysql -u root -e $mysqlCmd
    } catch {
        Write-Warning "Failed to automatically configure MariaDB."
    }
} elseif ($DbType -eq "postgres" -or $DbType -eq "postgresql") {
    try {
        $dbExists = (psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DbName'" | Out-String).Trim()
        if ($dbExists -ne "1") { psql -U postgres -c "CREATE DATABASE $DbName;" }
        $userExists = (psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = '$DbUser'" | Out-String).Trim()
        if ($userExists -ne "1") { psql -U postgres -c "CREATE USER $DbUser WITH PASSWORD '$DbPass';" }
        psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DbName TO $DbUser;"
    } catch {
        Write-Warning "Failed to automatically configure PostgreSQL."
    }
}

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

if ($WebServer -eq "iis" -and -not $env:PHP_FPM_LISTEN) {
    $phpExe = (Get-Command php.exe).Source
    $phpDir = Split-Path -Parent $phpExe
    $phpCgi = Join-Path $phpDir "php-cgi.exe"
    if (Test-Path $phpCgi) {
        $env:PHP_FPM_LISTEN = $phpCgi
    }
}

if ($WebServer -eq "iis") {
    $env:SERVER_NAME = $ServerName
    $env:LISTEN = $ListenPort
    $env:WWWROOT = $WwwRoot

    $iisCreateServer = Join-Path $libDir "_server\iis\create_server_block.ps1"
    if (Test-Path $iisCreateServer) {
        Write-Host "Configuring IIS Block..."
        & $iisCreateServer
    }
} else {
    Write-Warning "Web server '$WebServer' is not fully automated on Windows by this script. Please configure manually."
}

Write-Host "Nextcloud setup complete on $ServerName (Port $ListenPort)"