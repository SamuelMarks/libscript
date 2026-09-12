@echo off
REM ## Overview
REM Environment variable initialization script for the helm component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%HELM_VERSION%"=="" (
    set "HELM_VERSION=latest"
)
set "PATH=%LIBSCRIPT_HOME%\helm\%HELM_VERSION%\bin;%PATH%"
