@echo off
REM ## Overview
REM Environment variable initialization script for the sdkman component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%SDKMAN_VERSION%"=="" SET "SDKMAN_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\sdkman\%SDKMAN_VERSION%\bin;%PATH%"
