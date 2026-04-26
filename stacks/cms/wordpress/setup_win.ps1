$ErrorActionPreference = "Stop"

$WordpressVersion = if ($env:WORDPRESS_VERSION) { $env:WORDPRESS_VERSION } else { "latest" }
$WwwRoot = if ($env:WWWROOT) { $env:WWWROOT } else { "C:\inetpub\wwwroot\wordpress" }
$DbName = if ($env:WORDPRESS_DB_NAME) { $env:WORDPRESS_DB_NAME } else { "wordpress" }
$DbUser = if ($env:WORDPRESS_DB_USER) { $env:WORDPRESS_DB_USER } else { "wordpress" }
$DbPass = if ($env:WORDPRESS_DB_PASS) { $env:WORDPRESS_DB_PASS } else { "wordpress" }
$ServerName = if ($env:WORDPRESS_SERVER_NAME) { $env:WORDPRESS_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:WORDPRESS_LISTEN) { $env:WORDPRESS_LISTEN } else { "80" }
$DbEngine = if ($env:WORDPRESS_DB_ENGINE) { $env:WORDPRESS_DB_ENGINE } else { "mariadb" }
$WebServer = if ($env:WORDPRESS_WEBSERVER) { $env:WORDPRESS_WEBSERVER } else { "iis" }

log_info "Installing dependencies for WordPress ($WebServer)..."
depends @("PHP.PHP")

if ($DbEngine -eq "sqlite") {
    log_info "Using SQLite..."
} elseif ($DbEngine -match "postgres") {
    depends @("PostgreSQL.PostgreSQL")
} else {
    depends @("MariaDB.Server")
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
Remove-Item -Path $tmpZip -Force
Remove-Item -Path $tmpExtDir -Recurse -Force

log_info "Configuring Database..."
if ($DbEngine -eq "sqlite") {
    $dbFile = Join-Path $WwwRoot "wp-content\db.php"
    if (-not (Test-Path $dbFile)) {
        $muDir = Join-Path $WwwRoot "wp-content\mu-plugins"
        New-Item -ItemType Directory -Force -Path $muDir | Out-Null
        $tmpSqlite = Join-Path $env:TEMP "sqlite-integration.zip"
        $dlSqliteUrl = "https://downloads.wordpress.org/plugin/sqlite-database-integration.zip"
        libscript_download $dlSqliteUrl $tmpSqlite
        Expand-Archive -Path $tmpSqlite -DestinationPath (Join-Path $WwwRoot "wp-content\plugins") -Force
        Copy-Item -Path (Join-Path $WwwRoot "wp-content\plugins\sqlite-database-integration\db.copy") -Destination $dbFile -Force
        Remove-Item -Path $tmpSqlite -Force
        
        $content = Get-Content $dbFile
        $content = $content -replace '\{SQLITE_DB_DROPIN_VERSION\}', '1.0.0'
        $content = $content -replace '\{SQLITE_PLUGIN\}', 'sqlite-database-integration/load.php'
        Set-Content -Path $dbFile -Value $content
        log_success "SQLite database integration plugin installed."
    }
} elseif ($DbEngine -match "postgres") {
    $dbFile = Join-Path $WwwRoot "wp-content\db.php"
    if (-not (Test-Path $dbFile)) {
        $tmpPg = Join-Path $env:TEMP "pg4wp.zip"
        $dlPgUrl = "https://downloads.wordpress.org/plugin/postgresql-for-wordpress.zip"
        libscript_download $dlPgUrl $tmpPg
        Expand-Archive -Path $tmpPg -DestinationPath (Join-Path $WwwRoot "wp-content") -Force
        Move-Item -Path (Join-Path $WwwRoot "wp-content\postgresql-for-wordpress\pg4wp") -Destination (Join-Path $WwwRoot "wp-content") -Force
        Copy-Item -Path (Join-Path $WwwRoot "wp-content\pg4wp\db.php") -Destination $dbFile -Force
        Remove-Item -Path $tmpPg -Force
        log_success "PostgreSQL drop-in installed."
    }
    try {
        $dbExists = (psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DbName'" | Out-String).Trim()
        if ($dbExists -ne "1") { psql -U postgres -c "CREATE DATABASE `"$DbName`";" }
        $userExists = (psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = '$DbUser'" | Out-String).Trim()
        if ($userExists -ne "1") { psql -U postgres -c "CREATE USER `"$DbUser`" WITH ENCRYPTED PASSWORD '$DbPass';" }
        psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE `"$DbName`" TO `"$DbUser`";"
    } catch {
        Write-Warning "Failed to automatically configure PostgreSQL. You may need to create the database manually."
    }
} else {
    try {
        $mysqlCmd = "CREATE DATABASE IF NOT EXISTS `$DbName`; CREATE USER IF NOT EXISTS '$DbUser'@'localhost' IDENTIFIED BY '$DbPass'; GRANT ALL PRIVILEGES ON `$DbName`.* TO '$DbUser'@'localhost'; FLUSH PRIVILEGES;"
        mysql -u root -e $mysqlCmd
    } catch {
        Write-Warning "Failed to automatically configure MariaDB. You may need to create the database manually."
    }
}

$wpConfigSample = Join-Path $WwwRoot "wp-config-sample.php"
$wpConfig = Join-Path $WwwRoot "wp-config.php"

if (-not (Test-Path $wpConfig)) {
    $content = Get-Content $wpConfigSample
    $content = $content -replace 'database_name_here', $DbName
    $content = $content -replace 'username_here', $DbUser
    $content = $content -replace 'password_here', $DbPass
    Set-Content -Path $wpConfig -Value $content
}

# Resolve PHP-CGI executable for IIS
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

Write-Host "WordPress setup complete on $ServerName (Port $ListenPort)"
