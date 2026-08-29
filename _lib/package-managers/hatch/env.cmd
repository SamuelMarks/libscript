@echo off
REM ## Overview
REM Environment variable initialization script for the hatch component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%HATCH_VERSION%"=="" SET "HATCH_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%HATCH_VERSION%\bin;%PATH%"
