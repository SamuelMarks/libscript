@echo off
:: # test.cmd
:: ## Overview
:: Runs the test suite and validation scripts for the 'netctl' stack on Windows, verifying SPA fallback, WebSocket Upgrade headers, WASM MIME types, and domain configuration.
:: ## Usage
:: Execute this script to test netctl functionality.

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0
echo Runs the test suite and validation scripts for the 'netctl' stack.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Executes the primary orchestration workflow for this script.
:main
set "TMP_NGINX=%TEMP%\netctl_test_%RANDOM%.conf"
call "!SCRIPT_DIR!\cli.cmd" --domain example.local --listen 8080 --spa / "/var/www/app" --ws /ws "ws://127.0.0.1:8000/ws" --proxy /api "http://127.0.0.1:8000" --emit nginx > "!TMP_NGINX!"
findstr /C:"server_name example.local;" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    exit /b 1
)
findstr /C:"proxy_connect_timeout 60s;" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    exit /b 1
)
findstr /C:"proxy_send_timeout 300s;" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    exit /b 1
)
findstr /C:"proxy_read_timeout 300s;" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    exit /b 1
)
findstr /C:"proxy_buffering off;" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    exit /b 1
)
findstr /C:"proxy_cache off;" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    exit /b 1
)
findstr /C:"application/wasm wasm;" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    exit /b 1
)
findstr /C:"try_files $uri $uri/ /index.html;" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    exit /b 1
)
findstr /C:"location ^~ /.well-known/acme-challenge/" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    exit /b 1
)
del "!TMP_NGINX!" >nul 2>&1

set "STACK="
call "!SCRIPT_DIR!\netctl.cmd" --domain example.local --listen 80 --listen 443 --proxy-read-timeout 600s --proxy /api "http://127.0.0.1:8000" --emit nginx > "!TMP_NGINX!"
findstr /C:"proxy_read_timeout 600s;" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    exit /b 1
)
del "!TMP_NGINX!" >nul 2>&1

set "TMP_CSTORE=%TEMP%\netctl_cstore_%RANDOM%"
if not exist "!TMP_CSTORE!\live\secure.example.org" if not exist "!TMP_CSTORE!\live\secure.example.org" mkdir "!TMP_CSTORE!\live\secure.example.org" >nul 2>&1
echo cert > "!TMP_CSTORE!\live\secure.example.org\fullchain.pem"
echo key > "!TMP_CSTORE!\live\secure.example.org\privkey.pem"
set "STACK="
call "!SCRIPT_DIR!\cli.cmd" --domain secure.example.org --tls letsencrypt --cert-store-dir "!TMP_CSTORE!" --listen 80 --listen 443 --spa / "/var/www/app" --emit nginx > "!TMP_NGINX!"
findstr /C:"ssl_certificate !TMP_CSTORE!/live/secure.example.org/fullchain.pem;" "!TMP_NGINX!" >nul 2>&1
if errorlevel 1 (
    del "!TMP_NGINX!" >nul 2>&1
    rmdir /s /q "!TMP_CSTORE!" >nul 2>&1
    exit /b 1
)
del "!TMP_NGINX!" >nul 2>&1
rmdir /s /q "!TMP_CSTORE!" >nul 2>&1
echo netctl test pass
exit /b 0
