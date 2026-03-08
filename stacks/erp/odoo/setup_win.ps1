$ErrorActionPreference = "Stop"

$OdooVersion = if ($env:ODOO_VERSION) { $env:ODOO_VERSION } else { "17.0" }
$WwwRoot = if ($env:WWWROOT) { $env:WWWROOT } else { "C:\inetpub\wwwroot\odoo" }
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

if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    Write-Host "Python not found. Attempting to install via Winget..."
    winget install --silent --force --id=Python.Python.3.11 --accept-package-agreements --accept-source-agreements
}

if ($DbType -eq "postgres") {
    if (-not (Get-Command "psql" -ErrorAction SilentlyContinue)) {
        Write-Host "PostgreSQL not found. Attempting to install via Winget..."
        winget install --silent --force --id=PostgreSQL.PostgreSQL --accept-package-agreements --accept-source-agreements
    }
} elseif ($DbType -eq "mariadb") {
    if (-not (Get-Command "mysql" -ErrorAction SilentlyContinue)) {
        Write-Host "MariaDB not found. Attempting to install via Winget..."
        winget install --silent --force --id=MariaDB.Server --accept-package-agreements --accept-source-agreements
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

Write-Host "Downloading Odoo ($OdooVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

$tmpZip = Join-Path $env:TEMP "odoo_$(Get-Random).zip"
$tmpExtDir = Join-Path $env:TEMP "odoo_extract_$(Get-Random)"
$dlUrl = "https://github.com/odoo/odoo/archive/refs/heads/${OdooVersion}.zip"

if (-not (Test-Path (Join-Path $WwwRoot "odoo-bin"))) {
    Invoke-WebRequest -Uri $dlUrl -OutFile $tmpZip
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
if ($DbType -eq "postgres") {
    try {
        $psqlCmd = "CREATE USER $DbUser WITH PASSWORD '$DbPass'; ALTER USER $DbUser CREATEDB; CREATE DATABASE $DbName OWNER $DbUser;"
        psql -U postgres -c $psqlCmd
    } catch {
        Write-Warning "Failed to automatically configure PostgreSQL. You may need to create the database manually."
    }
} elseif ($DbType -eq "mariadb") {
    try {
        $mysqlCmd = "CREATE DATABASE IF NOT EXISTS `$DbName`; CREATE USER IF NOT EXISTS '$DbUser'@'localhost' IDENTIFIED BY '$DbPass'; GRANT ALL PRIVILEGES ON `$DbName`.* TO '$DbUser'@'localhost'; FLUSH PRIVILEGES;"
        mysql -u root -e $mysqlCmd
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
    $env:SERVER_NAME = $ServerName
    $env:LISTEN = $ListenPort
    $env:WWWROOT = $WwwRoot
    $env:PROXY_PASS = "http://127.0.0.1:${OdooPort}"
    $env:PROXY_WEBSOCKETS = "1"

    $iisCreateServer = Join-Path $libDir "_server\iis\create_server_block.ps1"
    if (Test-Path $iisCreateServer) {
        Write-Host "Configuring IIS Block..."
        & $iisCreateServer
    }
} else {
    Write-Warning "Web server '$WebServer' is not fully automated on Windows by this script. Please configure manually."
}

Write-Host "Odoo setup complete on $ServerName (Port $ListenPort)"
