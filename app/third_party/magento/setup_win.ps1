$ErrorActionPreference = "Stop"

$MagentoVersion = if ($env:MAGENTO_VERSION) { $env:MAGENTO_VERSION } else { "2.4.6" }
$WwwRoot = if ($env:WWWROOT) { $env:WWWROOT } else { "C:\inetpub\wwwroot\magento" }
$DbDriver = if ($env:MAGENTO_DB_DRIVER) { $env:MAGENTO_DB_DRIVER } else { "mariadb" }
$DbName = if ($env:MAGENTO_DB_NAME) { $env:MAGENTO_DB_NAME } else { "magento" }
$DbUser = if ($env:MAGENTO_DB_USER) { $env:MAGENTO_DB_USER } else { "magento" }
$DbPass = if ($env:MAGENTO_DB_PASS) { $env:MAGENTO_DB_PASS } else { "magento" }
$DbHost = if ($env:MAGENTO_DB_HOST) { $env:MAGENTO_DB_HOST } else { "127.0.0.1" }
$ServerName = if ($env:MAGENTO_SERVER_NAME) { $env:MAGENTO_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:MAGENTO_LISTEN) { $env:MAGENTO_LISTEN } else { "80" }
$WebServer = if ($env:MAGENTO_WEBSERVER) { $env:MAGENTO_WEBSERVER } else { "iis" }

Write-Host "Installing dependencies for Magento ($WebServer)..."
if (-not (Get-Command "php" -ErrorAction SilentlyContinue)) {
    Write-Host "PHP not found. Attempting to install via Winget..."
    winget install --silent --force --id=PHP.PHP --accept-package-agreements --accept-source-agreements
}

if (-not (Get-Command "composer" -ErrorAction SilentlyContinue)) {
    Write-Host "Composer not found. Attempting to install via Winget..."
    winget install --silent --force --id=Composer.Composer --accept-package-agreements --accept-source-agreements
}

if ($DbDriver -in @("mariadb", "mysql")) {
    if (-not (Get-Command "mysql" -ErrorAction SilentlyContinue)) {
        Write-Host "MariaDB not found. Attempting to install via Winget..."
        winget install --silent --force --id=MariaDB.Server --accept-package-agreements --accept-source-agreements
    }
} elseif ($DbDriver -in @("postgres", "postgresql")) {
    if (-not (Get-Command "psql" -ErrorAction SilentlyContinue)) {
        Write-Host "PostgreSQL not found. Attempting to install via Winget..."
        winget install --silent --force --id=PostgreSQL.PostgreSQL --accept-package-agreements --accept-source-agreements
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$libDir = Resolve-Path (Join-Path $scriptDir "..\..\..\_lib\")

if ($WebServer -eq "iis") {
    $iisSetup = Join-Path $libDir "_server\iis\setup_win.ps1"
    if (Test-Path $iisSetup) {
        Write-Host "Running IIS Setup..."
        & $iisSetup
    } else {
        Write-Warning "IIS setup script not found at $iisSetup. Assuming IIS is already configured."
    }
}

Write-Host "Downloading Magento ($MagentoVersion)..."
if (-not (Test-Path "$WwwRoot\app")) {
    if (-not (Test-Path $WwwRoot)) {
        New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
    }

    $tmpZip = Join-Path $env:TEMP "magento_$(Get-Random).zip"
    $tmpExtDir = Join-Path $env:TEMP "mag_extract_$(Get-Random)"
    $dlUrl = "https://github.com/magento/magento2/archive/refs/tags/${MagentoVersion}.zip"

    Invoke-WebRequest -Uri $dlUrl -OutFile $tmpZip
    New-Item -ItemType Directory -Force -Path $tmpExtDir | Out-Null
    Expand-Archive -Path $tmpZip -DestinationPath $tmpExtDir -Force
    
    $extractedFolder = Get-ChildItem -Path $tmpExtDir -Directory | Select-Object -First 1
    Copy-Item -Path "$($extractedFolder.FullName)\*" -Destination $WwwRoot -Recurse -Force
    Remove-Item -Path $tmpZip -Force
    Remove-Item -Path $tmpExtDir -Recurse -Force

    if (Get-Command "composer" -ErrorAction SilentlyContinue) {
        Set-Location $WwwRoot
        & composer install --no-interaction
    }
}

Write-Host "Configuring Database ($DbDriver)..."
if ($DbDriver -in @("mariadb", "mysql")) {
    try {
        $mysqlCmd = "CREATE DATABASE IF NOT EXISTS `$DbName`; CREATE USER IF NOT EXISTS '$DbUser'@'$DbHost' IDENTIFIED BY '$DbPass'; GRANT ALL PRIVILEGES ON `$DbName`.* TO '$DbUser'@'$DbHost'; FLUSH PRIVILEGES;"
        mysql -u root -e $mysqlCmd
    } catch {
        Write-Warning "Failed to automatically configure MariaDB. You may need to create the database manually."
    }
} elseif ($DbDriver -in @("postgres", "postgresql")) {
    try {
        $psqlCmds = "CREATE DATABASE $DbName; CREATE USER $DbUser WITH ENCRYPTED PASSWORD '$DbPass'; GRANT ALL PRIVILEGES ON DATABASE $DbName TO $DbUser;"
        psql -U postgres -c $psqlCmds
    } catch {
        Write-Warning "Failed to automatically configure PostgreSQL. You may need to create the database manually."
    }
} elseif ($DbDriver -eq "sqlite") {
    try {
        if (Get-Command "sqlite3" -ErrorAction SilentlyContinue) {
            sqlite3 "$WwwRoot\magento.sqlite" "VACUUM;"
        }
    } catch {
        Write-Warning "Failed to automatically configure SQLite."
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
    $env:WWWROOT = "$WwwRoot\pub"

    $iisCreateServer = Join-Path $libDir "_server\iis\create_server_block.ps1"
    if (Test-Path $iisCreateServer) {
        Write-Host "Configuring IIS Block..."
        & $iisCreateServer
    }
} else {
    Write-Warning "Web server '$WebServer' is not fully automated on Windows by this script. Please configure manually."
}

Write-Host "Magento setup complete on $ServerName (Port $ListenPort)"
