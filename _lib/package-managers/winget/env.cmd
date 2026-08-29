@echo off
REM ## Overview
REM Environment variable initialization script for the winget component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%WINGET_VERSION%"=="" SET "WINGET_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\winget\%WINGET_VERSION%\bin;%PATH%"
