@echo off
REM ## Overview
REM Environment variable initialization script for the guix component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%GUIX_VERSION%"=="" (
    set "GUIX_VERSION=latest"
)
set "PATH=%LIBSCRIPT_HOME%\guix\%GUIX_VERSION%\bin;%PATH%"
