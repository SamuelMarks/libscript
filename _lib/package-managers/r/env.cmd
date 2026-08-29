@echo off
REM ## Overview
REM Environment variable initialization script for the r component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%R_VERSION%"=="" SET "R_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\r\%R_VERSION%\bin;%PATH%"
