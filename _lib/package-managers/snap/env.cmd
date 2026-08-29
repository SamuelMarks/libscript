@echo off
REM ## Overview
REM Environment variable initialization script for the snap component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%SNAP_VERSION%"=="" SET "SNAP_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\snap\%SNAP_VERSION%\bin;%PATH%"
