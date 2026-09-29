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

:: # deprovision_schema.cmd
::
:: ## Overview
:: Non-destructive universal multi-tenant database schema deprovisioner on Windows.
:: Drops only the specified tenant application schema and user account.
:: GUARANTEE: Never stops, uninstalls, or harms the shared database server daemon.
::
:: ## Usage
::   call deprovision_schema.cmd [OPTIONS]

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

:parse_loop
if "%~1"=="" goto done_parse
if /i "%~1"=="--engine" ( set "ENGINE=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--host" ( set "HOST=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--port" ( set "PORT=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--admin-user" ( set "ADMIN_USER=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--admin-pass" ( set "ADMIN_PASS=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--schema" ( set "SCHEMA_NAME=%~2" & shift & shift & goto parse_loop )
if /i "%~1"=="--user" ( set "APP_USER=%~2" & shift & shift & goto parse_loop )
echo [ERROR] Unknown option: %~1 >&2
exit /b 1

:done_parse

if "%SCHEMA_NAME%"=="" (
    echo [ERROR] --schema name is required >&2
    exit /b 1
)

:: ## execute_deprovisioning
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$engine = '%ENGINE%';" ^
    "$host_val = '%HOST%';" ^
    "$port = '%PORT%';" ^
    "$admin_user = '%ADMIN_USER%';" ^
    "$admin_pass = '%ADMIN_PASS%';" ^
    "$schema = '%SCHEMA_NAME%';" ^
    "$user = '%APP_USER%';" ^
    "if ($engine -in @('mysql','mariadb')) {" ^
    "  if (-not $port) { $port = '3306'; };" ^
    "  if (-not $admin_user) { $admin_user = 'root'; };" ^
    "  $cmd = 'mysql';" ^
    "  if (Get-Command mariadb -ErrorAction SilentlyContinue) { $cmd = 'mariadb'; };" ^
    "  $pArg = if ($admin_pass) { '-p' + $admin_pass } else { '' };" ^
    "  & $cmd -h $host_val -P $port -u $admin_user $pArg -e ('DROP DATABASE IF EXISTS `' + $schema + '`;');" ^
    "  if ($user) {" ^
    "    & $cmd -h $host_val -P $port -u $admin_user $pArg -e ('DROP USER IF EXISTS ''' + $user + '''@''localhost''; DROP USER IF EXISTS ''' + $user + '''@''127.0.0.1''; DROP USER IF EXISTS ''' + $user + '''@''%''; FLUSH PRIVILEGES;');" ^
    "  }" ^
    "} elseif ($engine -in @('postgres','postgresql')) {" ^
    "  if (-not $port) { $port = '5432'; };" ^
    "  if (-not $admin_user) { $admin_user = 'postgres'; };" ^
    "  $env:PGPASSWORD = $admin_pass; $env:PGHOST = $host_val; $env:PGPORT = $port; $env:PGUSER = $admin_user;" ^
    "  & psql -c ('DROP DATABASE IF EXISTS "' + $schema + '";');" ^
    "  if ($user) { & psql -c ('DROP USER IF EXISTS "' + $user + '";'); };" ^
    "} elseif ($engine -eq 'sqlite') {" ^
    "  if (Test-Path $schema) { Remove-Item -Path $schema -Force; };" ^
    "};" ^
    "Write-Output ('[SUCCESS] Database schema ' + $schema + ' successfully deprovisioned.');"

exit /b %ERRORLEVEL%
