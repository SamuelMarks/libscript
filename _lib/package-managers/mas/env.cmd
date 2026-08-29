@echo off
REM ## Overview
REM Environment variable initialization script for the mas component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%MAS_VERSION%"=="" SET "MAS_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\mas\%MAS_VERSION%\bin;%PATH%"
