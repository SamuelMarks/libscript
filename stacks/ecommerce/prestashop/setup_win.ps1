$ErrorActionPreference = "Stop"

$PrestashopVersion = if ($env:PRESTASHOP_VERSION) { $env:PRESTASHOP_VERSION } else { "8.2.4" }
$WwwRoot = if ($env:WWWROOT) { $env:WWWROOT } else { "C:\inetpub\wwwroot\prestashop" }
$DbType = if ($env:PRESTASHOP_DB_TYPE) { $env:PRESTASHOP_DB_TYPE } else { "mariadb" }
$DbName = if ($env:PRESTASHOP_DB_NAME) { $env:PRESTASHOP_DB_NAME } else { "prestashop" }
$DbUser = if ($env:PRESTASHOP_DB_USER) { $env:PRESTASHOP_DB_USER } else { "prestashop" }
$DbPass = if ($env:PRESTASHOP_DB_PASS) { $env:PRESTASHOP_DB_PASS } else { "prestashop" }
$ServerName = if ($env:PRESTASHOP_SERVER_NAME) { $env:PRESTASHOP_SERVER_NAME } else { "localhost" }
$ListenPort = if ($env:PRESTASHOP_LISTEN) { $env:PRESTASHOP_LISTEN } else { "80" }
$WebServer = if ($env:PRESTASHOP_WEBSERVER) { $env:PRESTASHOP_WEBSERVER } else { "iis" }

Write-Host "Installing dependencies for PrestaShop ($WebServer)..."
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

Write-Host "Downloading PrestaShop ($PrestashopVersion)..."
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

if (-not (Test-Path (Join-Path $WwwRoot "classes")) -and -not (Test-Path (Join-Path $WwwRoot "install"))) {
    $tmpZip = Join-Path $env:TEMP "prestashop_$(Get-Random).zip"
    $tmpExtDir = Join-Path $env:TEMP "ps_extract_$(Get-Random)"
    $dlUrl = "https://github.com/PrestaShop/PrestaShop/releases/download/$PrestashopVersion/prestashop_$PrestashopVersion.zip"

    Invoke-WebRequest -Uri $dlUrl -OutFile $tmpZip
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
if ($DbType -eq "mariadb" -or $DbType -eq "mysql") {
    try {
        $mysqlCmd = "CREATE DATABASE IF NOT EXISTS `$DbName`; CREATE USER IF NOT EXISTS '$DbUser'@'localhost' IDENTIFIED BY '$DbPass'; GRANT ALL PRIVILEGES ON `$DbName`.* TO '$DbUser'@'localhost'; FLUSH PRIVILEGES;"
        mysql -u root -e $mysqlCmd
    } catch {
        Write-Warning "Failed to automatically configure MariaDB. You may need to create the database manually."
    }
} elseif ($DbType -eq "postgres" -or $DbType -eq "postgresql") {
    try {
        $psqlCmd = "psql -U postgres -tc `"SELECT 1 FROM pg_database WHERE datname = '$DbName'`""
        $dbExists = Invoke-Expression $psqlCmd
        if (-not $dbExists -match "1") {
            Invoke-Expression "psql -U postgres -c `"CREATE DATABASE $DbName`""
        }
        $psqlCmdUser = "psql -U postgres -tc `"SELECT 1 FROM pg_roles WHERE rolname = '$DbUser'`""
        $userExists = Invoke-Expression $psqlCmdUser
        if (-not $userExists -match "1") {
            Invoke-Expression "psql -U postgres -c `"CREATE USER $DbUser WITH PASSWORD '$DbPass'`""
        }
        Invoke-Expression "psql -U postgres -c `"GRANT ALL PRIVILEGES ON DATABASE $DbName TO $DbUser`""
    } catch {
        Write-Warning "Failed to automatically configure PostgreSQL. You may need to create the database manually."
    }
} elseif ($DbType -eq "sqlite") {
    $sqliteDir = Join-Path $WwwRoot "var\sqlite"
    if (-not (Test-Path $sqliteDir)) {
        New-Item -ItemType Directory -Force -Path $sqliteDir | Out-Null
    }
}

if ($WebServer -eq "iis" -and -not $env:PHP_FPM_LISTEN) {
    $phpExe = (Get-Command php.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
    if ($phpExe) {
        $phpDir = Split-Path -Parent $phpExe
        $phpCgi = Join-Path $phpDir "php-cgi.exe"
        if (Test-Path $phpCgi) {
            $env:PHP_FPM_LISTEN = $phpCgi
        }
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

Write-Host "PrestaShop setup complete on $ServerName (Port $ListenPort)"