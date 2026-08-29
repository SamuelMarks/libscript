@echo off
REM ## Overview
REM Environment variable initialization script for the zypper component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%ZYPPER_VERSION%"=="" SET "ZYPPER_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\zypper\%ZYPPER_VERSION%\bin;%PATH%"
