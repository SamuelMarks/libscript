@echo off
:: # test_wordpress_dbaas.cmd
:: ## Overview
:: Functional test runner for WordPress DBaaS URL parser and configuration on Windows.
:: ## Usage
:: call tests\test_wordpress_dbaas.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found


echo ==^> [1/3] Testing DBaaS Connection URL Parser on Windows...
set "TEST_URL=mysql://wp_cloud_user:SecretPass2026@mysql-prod.cluster-123.us-east-1.rds.amazonaws.com:3306/wordpress_prod?ssl-ca=/etc/ssl/certs/rds-ca-2019-root.pem&ssl-mode=VERIFY_IDENTITY"
set "STACK="
for /f "tokens=1* delims==" %%A in ('call "%LIBSCRIPT_ROOT_DIR%\engine\hooks\databases\parse_dbaas_url.cmd" "%TEST_URL%" --eval') do (
    set "%%A=%%B"
)

if not "!DB_HOST!"=="mysql-prod.cluster-123.us-east-1.rds.amazonaws.com" (
    echo [ERROR] DB_HOST mismatch: !DB_HOST! >&2
    exit /b 1
)
if not "!DB_PORT!"=="3306" (
    echo [ERROR] DB_PORT mismatch: !DB_PORT! >&2
    exit /b 1
)
if not "!DB_NAME!"=="wordpress_prod" (
    echo [ERROR] DB_NAME mismatch: !DB_NAME! >&2
    exit /b 1
)
if not "!DB_USER!"=="wp_cloud_user" (
    echo [ERROR] DB_USER mismatch: !DB_USER! >&2
    exit /b 1
)
if not "!DB_USE_SSL!"=="1" (
    echo [ERROR] DB_USE_SSL mismatch: !DB_USE_SSL! >&2
    exit /b 1
)
if not "!DB_SSL_CA!"=="/etc/ssl/certs/rds-ca-2019-root.pem" (
    echo [ERROR] DB_SSL_CA mismatch: !DB_SSL_CA! >&2
    exit /b 1
)
if not "!DB_SSL_MODE!"=="VERIFY_IDENTITY" (
    echo [ERROR] DB_SSL_MODE mismatch: !DB_SSL_MODE! >&2
    exit /b 1
)
echo     [OK] Connection URL parsed accurately ^(Host, Port, User, SSL-CA, SSL-Mode^).

echo ==^> [2/3] Testing JSON Mode Output...
set "STACK="
set "JSON_OUT="
for /f "delims=" %%J in ('call "%LIBSCRIPT_ROOT_DIR%\engine\hooks\databases\parse_dbaas_url.cmd" "%TEST_URL%" --json') do set "JSON_OUT=%%J"
echo "!JSON_OUT!" | findstr /C:"\"use_ssl\":true" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] JSON output missing use_ssl:true: !JSON_OUT! >&2
    exit /b 1
)
echo     [OK] JSON mode output verified.

echo ==^> [3/3] Verifying WordPress setup_generic.cmd SSL Configuration Support...
findstr /I /C:"MYSQLI_CLIENT_SSL" "%LIBSCRIPT_ROOT_DIR%\workloads\apps\wordpress\setup_generic.sh" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] MYSQLI_CLIENT_SSL constant missing from WordPress configuration template. >&2
    exit /b 1
)
echo     [OK] WordPress DBaaS SSL constant verified.

echo ==^> All hosted DBaaS tests passed successfully on Windows^^!
exit /b 0
