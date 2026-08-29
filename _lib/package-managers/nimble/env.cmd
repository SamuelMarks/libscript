@echo off
REM ## Overview
REM Environment variable initialization script for the nimble component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%NIMBLE_VERSION%"=="" SET "NIMBLE_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\nimble\%NIMBLE_VERSION%\bin;%PATH%"
