@echo off
REM ## Overview
REM Environment variable initialization script for the fnm component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%FNM_VERSION%"=="" SET "FNM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%FNM_VERSION%\bin;%PATH%"
