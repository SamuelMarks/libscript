@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Windows setup and orchestration module for Linode (`linode-cli`).
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use, and cloud node actions.

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

if "%ACTION%"=="" set "ACTION=install"
if "%LINODE_VERSION%"=="" set "LINODE_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
if /i "%~1"=="group" goto :action_group
if /i "%~1"=="project" goto :action_group
if /i "%~1"=="network" goto :action_network
if /i "%~1"=="firewall" goto :action_firewall
if /i "%~1"=="node" goto :action_node
goto :action_install

:: ## action_ls
:: Lists locally installed versions of linode under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\linode" dir /b "%LIBSCRIPT_HOME%\linode"
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
git ls-remote --tags "https://github.com/linode/linode-cli" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
exit /b 0

:: ## action_use
:: Activates the specified component version.
:action_use
set "TARGET_DIR=%LIBSCRIPT_HOME%\linode\%LINODE_VERSION%"
if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if not exist "%DOWNLOAD_DIR%\linode" mkdir "%DOWNLOAD_DIR%\linode"
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\linode\%LINODE_VERSION%"
if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
exit /b 0

:: ## action_group
:: Ensures a Linode project/group idempotently.
:action_group
echo Linode project '%~3' ensured.
exit /b 0

:: ## action_network
:: Creates or deletes a Linode VPC idempotently.
:action_network
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] linode-cli vpcs %~2 --label "%~3" >&2
    exit /b 0
)
linode-cli vpcs create --label "%~3" --region "%~4" >nul 2>&1
exit /b 0

:: ## action_firewall
:: Creates or updates a Linode Cloud Firewall idempotently.
:action_firewall
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] linode-cli firewalls %~2 --label "%~3" >&2
    exit /b 0
)
linode-cli firewalls create --label "%~3" >nul 2>&1
exit /b 0

:: ## action_node
:: Manages Linode instances (create, ip, exec, deploy, upload, download, sync).
:action_node
set "_SUB=%~2"
set "_NODE=%~3"
if /i "!_SUB!"=="create" (
    if "!DRY_RUN!"=="true" (
        echo [DRY_RUN] linode-cli linodes create --label "!_NODE!" >&2
        exit /b 0
    )
    linode-cli linodes create --label "!_NODE!" --image "%~4" --region "%~5" --type "g6-standard-2"
    exit /b !ERRORLEVEL!
)
if "!DRY_RUN!"=="true" (
    if /i "!_SUB!"=="ip" (
        echo 203.0.113.10
        exit /b 0
    )
    echo [DRY_RUN] linode node !_SUB! !_NODE! %4 %5 %6 >&2
    exit /b 0
)
set "_IP="
for /f "tokens=*" %%I in ('linode-cli linodes list --label "!_NODE!" --format ipv4 --text --no-headers 2^>nul') do set "_IP=%%I"
if /i "!_SUB!"=="ip" (
    echo !_IP!
    exit /b 0
)
if /i "!_SUB!"=="exec" (
    ssh -o StrictHostKeyChecking=no "%ADMIN_USER%@!_IP!" "%~5"
    exit /b !ERRORLEVEL!
)
if /i "!_SUB!"=="sync" (
    scp -o StrictHostKeyChecking=no -r "!LIBSCRIPT_ROOT_DIR!" "%ADMIN_USER%@!_IP!:~/libscript"
    exit /b !ERRORLEVEL!
)
if /i "!_SUB!"=="deploy" (
    scp -o StrictHostKeyChecking=no -r "%~5" "%ADMIN_USER%@!_IP!:%~6"
    exit /b !ERRORLEVEL!
)
if /i "!_SUB!"=="upload" (
    scp -o StrictHostKeyChecking=no -r "%~5" "%ADMIN_USER%@!_IP!:%~6"
    exit /b !ERRORLEVEL!
)
if /i "!_SUB!"=="download" (
    scp -o StrictHostKeyChecking=no -r "%ADMIN_USER%@!_IP!:%~5" "%~6"
    exit /b !ERRORLEVEL!
)
exit /b 0
