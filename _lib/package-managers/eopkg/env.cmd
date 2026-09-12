@echo off
REM ## Overview
REM Environment variable initialization script for the eopkg component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%EOPKG_VERSION%"=="" (
    set "EOPKG_VERSION=latest"
)
set "PATH=%LIBSCRIPT_HOME%\eopkg\%EOPKG_VERSION%\bin;%PATH%"
