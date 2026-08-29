@echo off
REM ## Overview
REM Environment variable initialization script for the macports component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%MACPORTS_VERSION%"=="" SET "MACPORTS_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\macports\%MACPORTS_VERSION%\bin;%PATH%"
