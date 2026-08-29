@echo off
REM ## Overview
REM Environment variable initialization script for the google-cloud-sdk component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%GOOGLE_CLOUD_SDK_VERSION%"=="" SET "GOOGLE_CLOUD_SDK_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%GOOGLE_CLOUD_SDK_VERSION%\bin;%PATH%"
