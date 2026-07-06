@echo off
REM ## Overview
REM Environment variable initialization script for the eopkg component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%EOPKG_VERSION%"=="" SET "EOPKG_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%EOPKG_VERSION%\bin;%PATH%"
