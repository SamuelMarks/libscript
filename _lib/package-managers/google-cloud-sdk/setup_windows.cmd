@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for Google Cloud SDK on Windows.
:: Installs official Google Cloud SDK via winget using silent unattended parameters.
::
:: ## Usage
:: Automatically invoked during libscript google-cloud-sdk installation on Windows.

set "THIS_FILE=%~f0"

where gcloud >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "C:\GoogleCloudSDK\google-cloud-sdk\bin\gcloud.cmd" goto :create_shims
if exist "%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" goto :create_shims
if exist "%ProgramFiles(x86)%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" goto :create_shims
if exist "%ProgramFiles%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" goto :create_shims

echo Installing Google Cloud SDK via winget...
winget install --id Google.CloudSDK --silent --accept-package-agreements --accept-source-agreements --override "/S /D=C:\GoogleCloudSDK"

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
