@echo off
REM ## Overview
REM Environment variable initialization script for the gem component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%GEM_VERSION%"=="" (
    set "GEM_VERSION=latest"
)
set "PATH=%LIBSCRIPT_HOME%\gem\%GEM_VERSION%\bin;%PATH%"
