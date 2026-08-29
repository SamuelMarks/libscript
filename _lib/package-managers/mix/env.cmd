@echo off
REM ## Overview
REM Environment variable initialization script for the mix component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%MIX_VERSION%"=="" SET "MIX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\mix\%MIX_VERSION%\bin;%PATH%"
