@echo off
REM ## Overview
REM Environment variable initialization script for the hatch component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%HATCH_VERSION%"=="" (
    set "HATCH_VERSION=latest"
)
set "PATH=%LIBSCRIPT_HOME%\hatch\%HATCH_VERSION%\bin;%PATH%"
