@echo off
REM ## Overview
REM Environment variable initialization script for the sbt component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%SBT_VERSION%"=="" SET "SBT_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\sbt\%SBT_VERSION%\bin;%PATH%"
