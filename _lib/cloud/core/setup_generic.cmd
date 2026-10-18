@echo off
:: # setup.cmd
::
:: ## Overview
:: Action dispatcher for cloud core on Windows.
::
:: ## Usage
:: Handles sub-actions (`list-managed`, `status`, `diff`, `backup`, `restore`) by delegating to dedicated scripts.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

set "action=%ACTION%"

if /i "%action%"=="list-managed" goto handle_list_managed
if /i "%action%"=="status" goto handle_list_managed
if /i "%action%"=="diff" goto handle_diff
if /i "%action%"=="backup" (
    call "%~dp0backup_cloud.cmd" %*
    exit /b %errorlevel%
)
if /i "%action%"=="restore" (
    call "%~dp0restore_cloud.cmd" %*
    exit /b %errorlevel%
)
if /i "%action%"=="aws" goto :route_provider
if /i "%action%"=="azure" goto :route_provider
if /i "%action%"=="gcp" goto :route_provider
if /i "%action%"=="hetzner" goto :route_provider
if /i "%action%"=="proxmox" goto :route_provider

:: Default behavior (no-op)
goto :eof

:: ## route_provider
:: Dispatches cloud provider commands to the corresponding provider cli.cmd.
:route_provider
set "CLI_PATH=!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\%action%\cli.cmd"
if not exist "%CLI_PATH%" (
    echo Error: Provider %action% not supported or installed. 1>&2
    exit /b 1
)
call "%CLI_PATH%" %*
exit /b %errorlevel%

:: ## handle_diff
:: Performs the handle_diff operation and updates component state.
:handle_diff
echo Comparing local .libscript_state.json with cloud provider reality...
if not exist ".libscript_state.json" (
    echo No local .libscript_state.json found. All discovered resources are untracked.
)
echo --- AWS Drift
echo AWS Diff Placeholder
echo --- Azure Drift
echo Azure Diff Placeholder
echo --- GCP Drift
echo GCP Diff Placeholder
exit /b 0

:: ## handle_list_managed
:: Performs the handle_list_managed operation and updates component state.
:handle_list_managed
echo --- AWS Resources
where aws >nul 2>&1
if not errorlevel 1 (
    echo AWS Managed Resource Listing Placeholder
)
echo --- Azure Resources
where az >nul 2>&1
if not errorlevel 1 (
    echo Azure Managed Resource Listing Placeholder
)
echo --- GCP Resources
where gcloud >nul 2>&1
if not errorlevel 1 (
    echo GCP Managed Resource Listing Placeholder
)
exit /b 0
