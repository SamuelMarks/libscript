@echo off
REM ## Overview
REM Environment variable initialization script for the pnpm component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%PNPM_VERSION%"=="" SET "PNPM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pnpm\%PNPM_VERSION%\bin;%PATH%"
