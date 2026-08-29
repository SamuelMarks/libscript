@echo off
REM ## Overview
REM Environment variable initialization script for the julia component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%JULIA_VERSION%"=="" SET "JULIA_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\julia\%JULIA_VERSION%\bin;%PATH%"
