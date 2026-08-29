@echo off
REM ## Overview
REM Environment variable initialization script for the nuget component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%NUGET_VERSION%"=="" SET "NUGET_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\nuget\%NUGET_VERSION%\bin;%PATH%"
