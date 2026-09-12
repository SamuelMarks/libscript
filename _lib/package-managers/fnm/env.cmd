@echo off
REM ## Overview
REM Environment variable initialization script for the fnm component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%FNM_VERSION%"=="" (
    set "FNM_VERSION=latest"
)
set "PATH=%LIBSCRIPT_HOME%\fnm\%FNM_VERSION%\bin;%PATH%"
