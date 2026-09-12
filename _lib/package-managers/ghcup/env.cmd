@echo off
REM ## Overview
REM Environment variable initialization script for the ghcup component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%GHCUP_VERSION%"=="" (
    set "GHCUP_VERSION=latest"
)
set "PATH=%LIBSCRIPT_HOME%\ghcup\%GHCUP_VERSION%\bin;%PATH%"
