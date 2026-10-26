@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for Google Cloud SDK on Windows.
:: Installs official Google Cloud SDK via winget using silent unattended parameters.
::
:: ## Usage
:: Automatically invoked during libscript google-cloud-sdk installation on Windows.

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

where gcloud >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "C:\GoogleCloudSDK\google-cloud-sdk\bin\gcloud.cmd" goto :create_shims
if exist "%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" goto :create_shims
if exist "%ProgramFiles(x86)%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" goto :create_shims
if exist "%ProgramFiles%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" goto :create_shims

echo Installing Google Cloud SDK via pkg_mgr...
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends Google.CloudSDK

:: ## create_shims
:: Creates executable command shims in the local binary directory.
:create_shims
set "GCLOUD_BIN="
if exist "C:\GoogleCloudSDK\google-cloud-sdk\bin\gcloud.cmd" set "GCLOUD_BIN=C:\GoogleCloudSDK\google-cloud-sdk\bin"
if exist "%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" set "GCLOUD_BIN=%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin"
if exist "%ProgramFiles(x86)%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" set "GCLOUD_BIN=%ProgramFiles(x86)%\Google\Cloud SDK\google-cloud-sdk\bin"
if exist "%ProgramFiles%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" set "GCLOUD_BIN=%ProgramFiles%\Google\Cloud SDK\google-cloud-sdk\bin"

if defined GCLOUD_BIN (
    set "DEST_DIR=%USERPROFILE%\.libscript\google-cloud-sdk\latest\bin"
    if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"
    copy /y "!GCLOUD_BIN!\gcloud.*" "!DEST_DIR!" >nul 2>&1
    copy /y "!GCLOUD_BIN!\gsutil.*" "!DEST_DIR!" >nul 2>&1
    copy /y "!GCLOUD_BIN!\bq.*" "!DEST_DIR!" >nul 2>&1

    if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
    copy /y "!GCLOUD_BIN!\gcloud.*" "%USERPROFILE%\.local\bin" >nul 2>&1
    copy /y "!GCLOUD_BIN!\gsutil.*" "%USERPROFILE%\.local\bin" >nul 2>&1
    copy /y "!GCLOUD_BIN!\bq.*" "%USERPROFILE%\.local\bin" >nul 2>&1

    echo Google Cloud SDK installed successfully.
    exit /b 0
)

echo Failed to install Google Cloud SDK.
exit /b 1
