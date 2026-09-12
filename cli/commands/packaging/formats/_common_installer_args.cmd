@echo off
:: # _common_installer_args.cmd
::
:: ## Overview
:: Shared argument parser and utility functions for Windows package installers.
:: 
:: ## Usage
:: Call this script to parse installer arguments and generate GUIDs.

set "THIS_FILE=%~f0"

set "install_scope=perMachine"
set "inno_priv=admin"
set "nsis_admin=admin"
set "APP_NAME=LibScript Deployment"
set "APP_VERSION=1.0.0.0"
set "APP_PUBLISHER=LibScript"
set "APP_URL="
set "UPGRADE_CODE=PUT-GUID-HERE"
set "OUT_FILE=LibScriptInstaller"
set "ICON_PATH="
set "IMAGE_PATH="
set "LICENSE_PATH="
set "WELCOME_TEXT=Welcome to the LibScript Deployment Installer"
set "OFFLINE=0"

:: ## args_loop
:: Executes args_loop functionality.
:args_loop
if "%~1"=="" goto args_done
if /i "%~1"=="--user-mode" (
    set "install_scope=perUser"
    set "inno_priv=lowest"
    set "nsis_admin=user"
    shift
    goto args_loop
)
if /i "%~1"=="--elevated-mode" (
    set "install_scope=perMachine"
    set "inno_priv=admin"
    set "nsis_admin=admin"
    shift
    goto args_loop
)
if /i "%~1"=="--app-name" (
    set "APP_NAME=%~2"
    shift & shift
    goto args_loop
)
if /i "%~1"=="--app-version" (
    set "APP_VERSION=%~2"
    shift & shift
    goto args_loop
)
if /i "%~1"=="--app-publisher" (
    set "APP_PUBLISHER=%~2"
    shift & shift
    goto args_loop
)
if /i "%~1"=="--app-url" (
    set "APP_URL=%~2"
    shift & shift
    goto args_loop
)
if /i "%~1"=="--upgrade-code" (
    set "UPGRADE_CODE=%~2"
    shift & shift
    goto args_loop
)
if /i "%~1"=="--out-file" (
    set "OUT_FILE=%~2"
    shift & shift
    goto args_loop
)
if /i "%~1"=="--icon" (
    set "ICON_PATH=%~2"
    shift & shift
    goto args_loop
)
if /i "%~1"=="--image" (
    set "IMAGE_PATH=%~2"
    shift & shift
    goto args_loop
)
if /i "%~1"=="--license" (
    set "LICENSE_PATH=%~2"
    shift & shift
    goto args_loop
)
if /i "%~1"=="--welcome" (
    set "WELCOME_TEXT=%~2"
    shift & shift
    goto args_loop
)
if /i "%~1"=="--offline" (
    set "OFFLINE=1"
    shift
    goto args_loop
)
shift
goto args_loop

:: ## args_done
:: Executes args_done functionality.
:args_done
set "PRODUCT_CODE=*"
set "_SVC_NAME=%APP_NAME: =_%"
set "_UPGRADE_ID=%APP_NAME%|%_SVC_NAME%|x64"
set "_PRODUCT_ID=%APP_NAME%|%_SVC_NAME%|x64|%APP_VERSION%"

if "%UPGRADE_CODE%"=="PUT-GUID-HERE" (
    for /f "usebackq tokens=*" %%G in (`powershell -NoProfile -Command "$b = [System.Text.Encoding]::UTF8.GetBytes('%_UPGRADE_ID%'); $h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($b); $x = [System.BitConverter]::ToString($h).Replace('-', '').ToLower(); Write-Output ($x.Substring(0,8) + '-' + $x.Substring(8,4) + '-5' + $x.Substring(13,3) + '-a' + $x.Substring(17,3) + '-' + $x.Substring(20,12))"`) do set "UPGRADE_CODE=%%G"
)

exit /b 0
