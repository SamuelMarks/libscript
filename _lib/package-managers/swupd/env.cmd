@echo off
REM ## Overview
REM Environment variable initialization script for the swupd component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%SWUPD_VERSION%"=="" SET "SWUPD_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\swupd\%SWUPD_VERSION%\bin;%PATH%"
