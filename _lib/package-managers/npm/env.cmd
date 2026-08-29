@echo off
REM ## Overview
REM Environment variable initialization script for the npm component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%NPM_VERSION%"=="" SET "NPM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\npm\%NPM_VERSION%\bin;%PATH%"
