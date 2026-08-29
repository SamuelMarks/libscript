@echo off
REM ## Overview
REM Environment variable initialization script for the helm component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%HELM_VERSION%"=="" SET "HELM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%HELM_VERSION%\bin;%PATH%"
