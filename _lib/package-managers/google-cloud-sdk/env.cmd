@echo off
REM ## Overview
REM Environment variable initialization script for the google-cloud-sdk component.
REM It sets up necessary paths and environment variables required for the component
REM to function correctly within the libscript context.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%GOOGLE_CLOUD_SDK_VERSION%"=="" (
    set "GOOGLE_CLOUD_SDK_VERSION=latest"
)

set "_GCLOUD_BIN=%LIBSCRIPT_HOME%\google-cloud-sdk\%GOOGLE_CLOUD_SDK_VERSION%\bin"
echo ;%PATH%; | findstr /I /C:";%_GCLOUD_BIN%;" >nul 2>&1
if errorlevel 1 (
    set "PATH=%_GCLOUD_BIN%;%PATH%"
)

if "%CLOUDSDK_PYTHON%"=="" (
    where python3.12 >nul 2>&1
    if not errorlevel 1 (
        for /f "delims=" %%i in ('where python3.12 2^>nul') do if "%CLOUDSDK_PYTHON%"=="" set "CLOUDSDK_PYTHON=%%i"
    ) else (
        where python3.11 >nul 2>&1
        if not errorlevel 1 (
            for /f "delims=" %%i in ('where python3.11 2^>nul') do if "%CLOUDSDK_PYTHON%"=="" set "CLOUDSDK_PYTHON=%%i"
        )
    )
)
