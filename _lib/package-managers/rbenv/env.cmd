@echo off
REM ## Overview
REM Environment variable initialization script for the rbenv component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%RBENV_VERSION%"=="" SET "RBENV_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\rbenv\%RBENV_VERSION%\bin;%PATH%"
