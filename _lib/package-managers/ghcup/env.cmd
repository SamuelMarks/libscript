@echo off
REM ## Overview
REM Environment variable initialization script for the ghcup component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%GHCUP_VERSION%"=="" SET "GHCUP_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%GHCUP_VERSION%\bin;%PATH%"
