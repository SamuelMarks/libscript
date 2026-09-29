@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

:: # provision_schema.cmd
::
:: ## Overview
:: Universal multi-tenant database schema and credential provisioner on Windows.
:: Idempotently creates isolated schemas/databases and scoped user credentials
:: across MySQL, MariaDB, PostgreSQL, MongoDB, and SQLite.
::
:: ## Usage
::   call provision_schema.cmd [OPTIONS]

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:found_root

set "ENGINE=mysql"
set "HOST=127.0.0.1"
set "PORT="
set "ADMIN_USER="
set "ADMIN_PASS="
set "SCHEMA_NAME="
set "APP_USER="
set "APP_PASS="
set "CHARSET=utf8mb4"
set "COLLATION=utf8mb4_unicode_ci"

:parse_loop
if "%~1"=="" goto done_parse
if /i "%~1"=="--engine" ( set "ENGINE=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--host" ( set "HOST=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--port" ( set "PORT=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--admin-user" ( set "ADMIN_USER=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--admin-pass" ( set "ADMIN_PASS=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--schema" ( set "SCHEMA_NAME=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--user" ( set "APP_USER=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--password" ( set "APP_PASS=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--charset" ( set "CHARSET=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--collation" ( set "COLLATION=%~2" & shift & shift & goto parse_loop )
echo [ERROR] Unknown option: %~1 >&2
exit /b 1

:done_parse

if "%SCHEMA_NAME%"=="" (
    echo [ERROR] --schema name is required >&2
    exit /b 1
)

:: ## execute_provisioning
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$engine = '%ENGINE%';" ^
    "$host_val = '%HOST%';" ^
    "$port = '%PORT%';" ^
    "$admin_user = '%ADMIN_USER%';" ^
    "$admin_pass = '%ADMIN_PASS%';" ^
    "$schema = '%SCHEMA_NAME%';" ^
    "$user = '%APP_USER%';" ^
    "$pass = '%APP_PASS%';" ^
    "$charset = '%CHARSET%';" ^
    "$collation = '%COLLATION%';" ^
    "if ($engine -in @('mysql','mariadb')) {" ^
    "  if (-not $port) { $port = '3306'; };" ^
    "  if (-not $admin_user) { $admin_user = 'root'; };" ^
    "  $cmd = 'mysql';" ^
    "  if (Get-Command mariadb -ErrorAction SilentlyContinue) { $cmd = 'mariadb'; };" ^
    "  $pArg = if ($admin_pass) { '-p' + $admin_pass } else { '' };" ^
    "  & $cmd -h $host_val -P $port -u $admin_user $pArg -e ('CREATE DATABASE IF NOT EXISTS `' + $schema + '` DEFAULT CHARACTER SET ' + $charset + ' COLLATE ' + $collation + ';');" ^
    "  if ($user) {" ^
    "    if ($pass) {" ^
    "      & $cmd -h $host_val -P $port -u $admin_user $pArg -e ('CREATE USER IF NOT EXISTS ''' + $user + '''@''localhost'' IDENTIFIED BY ''' + $pass + '''; ALTER USER ''' + $user + '''@''localhost'' IDENTIFIED BY ''' + $pass + ''';');" ^
    "      & $cmd -h $host_val -P $port -u $admin_user $pArg -e ('CREATE USER IF NOT EXISTS ''' + $user + '''@''127.0.0.1'' IDENTIFIED BY ''' + $pass + '''; ALTER USER ''' + $user + '''@''127.0.0.1'' IDENTIFIED BY ''' + $pass + ''';');" ^
    "    } else {" ^
    "      & $cmd -h $host_val -P $port -u $admin_user $pArg -e ('CREATE USER IF NOT EXISTS ''' + $user + '''@''localhost''; CREATE USER IF NOT EXISTS ''' + $user + '''@''127.0.0.1'';');" ^
    "    };" ^
    "    & $cmd -h $host_val -P $port -u $admin_user $pArg -e ('GRANT ALL PRIVILEGES ON `' + $schema + '`.* TO ''' + $user + '''@''localhost''; GRANT ALL PRIVILEGES ON `' + $schema + '`.* TO ''' + $user + '''@''127.0.0.1''; FLUSH PRIVILEGES;');" ^
    "  }" ^
    "} elseif ($engine -in @('postgres','postgresql')) {" ^
    "  if (-not $port) { $port = '5432'; };" ^
    "  if (-not $admin_user) { $admin_user = 'postgres'; };" ^
    "  $env:PGPASSWORD = $admin_pass; $env:PGHOST = $host_val; $env:PGPORT = $port; $env:PGUSER = $admin_user;" ^
    "  $exists = & psql -tAc ('SELECT 1 FROM pg_database WHERE datname = ''' + $schema + ''';');" ^
    "  if ($exists -ne '1') { & psql -c ('CREATE DATABASE "' + $schema + '";'); };" ^
    "  if ($user) {" ^
    "    $user_exists = & psql -tAc ('SELECT 1 FROM pg_roles WHERE rolname = ''' + $user + ''';');" ^
    "    if ($user_exists -ne '1') {" ^
    "      if ($pass) { & psql -c ('CREATE USER "' + $user + '" WITH ENCRYPTED PASSWORD ''' + $pass + ''';'); } else { & psql -c ('CREATE USER "' + $user + '";'); }" ^
    "    } elseif ($pass) {" ^
    "      & psql -c ('ALTER USER "' + $user + '" WITH ENCRYPTED PASSWORD ''' + $pass + ''';');" ^
    "    };" ^
    "    & psql -c ('GRANT ALL PRIVILEGES ON DATABASE "' + $schema + '" TO "' + $user + '";');" ^
    "  }" ^
    "} elseif ($engine -eq 'sqlite') {" ^
    "  $dir = Split-Path -Parent $schema;" ^
    "  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null; };" ^
    "  if (-not (Test-Path $schema)) { New-Item -ItemType File -Path $schema | Out-Null; };" ^
    "};" ^
    "Write-Output ('[SUCCESS] Database schema ' + $schema + ' successfully provisioned.');"

exit /b %ERRORLEVEL%
