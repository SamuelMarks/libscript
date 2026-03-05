$ErrorActionPreference = "Stop"

$WordpressVersion = if ($env:WORDPRESS_VERSION) { $env:WORDPRESS_VERSION } else { "latest" }
$WwwRoot = if ($env:WWWROOT) { $env:WWWROOT } else { "C:\inetpub\wwwroot\wordpress" }
$DbName = if ($env:WORDPRESS_DB_NAME) { $env:WORDPRESS_DB_NAME } else { "wordpress" }
$DbUser = if ($env:WORDPRESS_DB_USER) { $env:WORDPRESS_DB_USER } else { "wordpress" }
$DbPass = if ($env:WORDPRESS_DB_PASS) { $env:WORDPRESS_DB_PASS } else { "wordpress" }
$ServerName = if ($env:WORDPRESS_SERVER_NAME) { $env:WORDPRESS_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:WORDPRESS_LISTEN) { $env:WORDPRESS_LISTEN } else { "80" }
$WebServer = if ($env:WORDPRESS_WEBSERVER) { $env:WORDPRESS_WEBSERVER } else { "iis" }

Write-Host "Installing dependencies for WordPress ($WebServer)..."
# In LibScript Windows, dependencies should be explicitly resolved via CLI or here
# We assume PHP and MariaDB are installed or we install them via winget
if (-not (Get-Command "php" -ErrorAction SilentlyContinue)) {
    Write-Host "PHP not found. Attempting to install via Winget..."
    winget install --id=PHP.PHP --accept-package-agreements --accept-source-agreements
}

if (-not (Get-Command "mysql" -ErrorAction SilentlyContinue)) {
    Write-Host "MariaDB not found. Attempting to install via Winget..."
    winget install --id=MariaDB.Server --accept-package-agreements --accept-source-agreements
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

Write-Host "Downloading WordPress ($WordpressVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

$tmpZip = Join-Path $env:TEMP "wordpress_$(Get-Random).zip"
$tmpExtDir = Join-Path $env:TEMP "wp_extract_$(Get-Random)"
$dlUrl = if ($WordpressVersion -eq "latest") { "https://wordpress.org/latest.zip" } else { "https://wordpress.org/wordpress-$WordpressVersion.zip" }

Invoke-WebRequest -Uri $dlUrl -OutFile $tmpZip
New-Item -ItemType Directory -Force -Path $tmpExtDir | Out-Null
Expand-Archive -Path $tmpZip -DestinationPath $tmpExtDir -Force
Copy-Item -Path (Join-Path $tmpExtDir "wordpress\*") -Destination $WwwRoot -Recurse -Force
Remove-Item -Path $tmpZip -Force
Remove-Item -Path $tmpExtDir -Recurse -Force

Write-Host "Configuring Database..."
# This assumes root has no password by default on a fresh mariadb install, or requires manual prep
try {
    $mysqlCmd = "CREATE DATABASE IF NOT EXISTS `$DbName`; CREATE USER IF NOT EXISTS '$DbUser'@'localhost' IDENTIFIED BY '$DbPass'; GRANT ALL PRIVILEGES ON `$DbName`.* TO '$DbUser'@'localhost'; FLUSH PRIVILEGES;"
    mysql -u root -e $mysqlCmd
} catch {
    Write-Warning "Failed to automatically configure MariaDB. You may need to create the database manually."
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
