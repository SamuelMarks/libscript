$ErrorActionPreference = "Stop"

$JoomlaVersion = if ($env:JOOMLA_VERSION) { $env:JOOMLA_VERSION } else { "latest" }
$WwwRoot = if ($env:WWWROOT) { $env:WWWROOT } else { "C:\inetpub\wwwroot\joomla" }
$DbName = if ($env:JOOMLA_DB_NAME) { $env:JOOMLA_DB_NAME } else { "joomla" }
$DbUser = if ($env:JOOMLA_DB_USER) { $env:JOOMLA_DB_USER } else { "joomla" }
$DbPass = if ($env:JOOMLA_DB_PASS) { $env:JOOMLA_DB_PASS } else { "joomla" }
$ServerName = if ($env:JOOMLA_SERVER_NAME) { $env:JOOMLA_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:JOOMLA_LISTEN) { $env:JOOMLA_LISTEN } else { "80" }
$WebServer = if ($env:JOOMLA_WEBSERVER) { $env:JOOMLA_WEBSERVER } else { "iis" }
$DbType = if ($env:JOOMLA_DB_TYPE) { $env:JOOMLA_DB_TYPE } else { "mariadb" }

Write-Host "Installing dependencies for Joomla ($WebServer)..."
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

Write-Host "Downloading Joomla ($JoomlaVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

if ($JoomlaVersion -eq "latest") {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/joomla/joomla-cms/releases/latest"
        $JoomlaVersion = $release.tag_name
    } catch {
        Write-Warning "Could not fetch latest version from GitHub API. Defaulting to 5.2.0"
        $JoomlaVersion = "5.2.0"
    }
}

$tmpZip = Join-Path $env:TEMP "joomla_$(Get-Random).zip"
$dlUrl = "https://github.com/joomla/joomla-cms/releases/download/$JoomlaVersion/Joomla_$JoomlaVersion-Stable-Full_Package.zip"

Invoke-WebRequest -Uri $dlUrl -OutFile $tmpZip
Expand-Archive -Path $tmpZip -DestinationPath $WwwRoot -Force
Remove-Item -Path $tmpZip -Force

Write-Host "Configuring Database..."
if ($DbType -eq "mariadb" -or $DbType -eq "mysql") {
    try {
        $mysqlCmd = "CREATE DATABASE IF NOT EXISTS `$DbName`; CREATE USER IF NOT EXISTS '$DbUser'@'localhost' IDENTIFIED BY '$DbPass'; GRANT ALL PRIVILEGES ON `$DbName`.* TO '$DbUser'@'localhost'; FLUSH PRIVILEGES;"
        mysql -u root -e $mysqlCmd
    } catch {
        Write-Warning "Failed to automatically configure MariaDB. You may need to create the database manually."
    }
} elseif ($DbType -eq "postgres" -or $DbType -eq "postgresql") {
    try {
        $userExists = (psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = '$DbUser'" | Out-String).Trim()
        if ($userExists -ne "1") { psql -U postgres -c "CREATE USER $DbUser WITH PASSWORD '$DbPass';" }
        $dbExists = (psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DbName'" | Out-String).Trim()
        if ($dbExists -ne "1") { psql -U postgres -c "CREATE DATABASE $DbName OWNER $DbUser;" }
        psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DbName TO $DbUser;"
    } catch {
        Write-Warning "Failed to automatically configure PostgreSQL. You may need to create the database manually."
    }
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

Write-Host "Joomla setup complete on $ServerName (Port $ListenPort)"
