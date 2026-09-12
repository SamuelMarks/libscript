@echo off
REM ## Overview
REM Environment variable initialization script for the flatpak component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%FLATPAK_VERSION%"=="" (
    set "FLATPAK_VERSION=latest"
)
set "PATH=%LIBSCRIPT_HOME%\flatpak\%FLATPAK_VERSION%\bin;%PATH%"
