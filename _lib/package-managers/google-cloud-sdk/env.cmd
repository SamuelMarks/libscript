@echo off
REM ## Overview
REM Environment variable initialization script for the google-cloud-sdk component.
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
set "PATH=%LIBSCRIPT_HOME%\google-cloud-sdk\%GOOGLE_CLOUD_SDK_VERSION%\bin;%PATH%"
