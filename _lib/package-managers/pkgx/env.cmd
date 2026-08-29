@echo off
REM ## Overview
REM Environment variable initialization script for the pkgx component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%PKGX_VERSION%"=="" SET "PKGX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pkgx\%PKGX_VERSION%\bin;%PATH%"
