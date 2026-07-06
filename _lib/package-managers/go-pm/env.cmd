@echo off
REM ## Overview
REM Environment variable initialization script for the go-pm component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%GO_PM_VERSION%"=="" SET "GO_PM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%GO_PM_VERSION%\bin;%PATH%"
