@echo off
REM ## Overview
REM Environment variable initialization script for the go-pm component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%GO_PM_VERSION%"=="" (
    set "GO_PM_VERSION=latest"
)
set "PATH=%LIBSCRIPT_HOME%\go-pm\%GO_PM_VERSION%\bin;%PATH%"
