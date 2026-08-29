@echo off
REM ## Overview
REM Environment variable initialization script for the yarn component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%YARN_VERSION%"=="" SET "YARN_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\yarn\%YARN_VERSION%\bin;%PATH%"
