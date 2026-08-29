@echo off
REM ## Overview
REM Environment variable initialization script for the rvm component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%RVM_VERSION%"=="" SET "RVM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\rvm\%RVM_VERSION%\bin;%PATH%"
