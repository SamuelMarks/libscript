@echo off
REM ## Overview
REM Environment variable initialization script for the rye component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%RYE_VERSION%"=="" SET "RYE_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\rye\%RYE_VERSION%\bin;%PATH%"
