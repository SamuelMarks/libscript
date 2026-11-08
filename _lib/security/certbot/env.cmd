@echo off
:: # env.cmd
:: ## Overview
:: Environment variable initialization script for the certbot component on Windows.
:: Exports persistent certificate storage paths and expiry-gated renewal settings.
:: ## Usage
:: Call this script to load certbot environment variables.

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

IF "%CERTBOT_VERSION%"=="" SET "CERTBOT_VERSION=latest"
IF "%CERT_STORE_DIR%"=="" (
    set "_CB_DEF_MOUNT=%DATA_DISK_MOUNT%"
    if "!_CB_DEF_MOUNT!"=="" set "_CB_DEF_MOUNT=%DATA_MOUNT_DIR%"
    if "!_CB_DEF_MOUNT!"=="" set "_CB_DEF_MOUNT=/mnt/data"
    SET "CERT_STORE_DIR=!_CB_DEF_MOUNT!/certs"
)
IF "%LETSENCRYPT_RENEW_BEFORE_SECONDS%"=="" SET "LETSENCRYPT_RENEW_BEFORE_SECONDS=0"
set "_CAND_P=%LIBSCRIPT_HOME%\certbot\%CERTBOT_VERSION%\bin"
echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "certbot"

endlocal & (
    set "CERTBOT_VERSION=%CERTBOT_VERSION%"
    set "CERT_STORE_DIR=%CERT_STORE_DIR%"
    set "LETSENCRYPT_RENEW_BEFORE_SECONDS=%LETSENCRYPT_RENEW_BEFORE_SECONDS%"
    set "PATH=%PATH%"
)
exit /b 0
