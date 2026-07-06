@echo off
REM ## Overview
REM Environment variable initialization script for the gcsfuse component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%GCSFUSE_VERSION%"=="" SET "GCSFUSE_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\gcsfuse\%GCSFUSE_VERSION%\bin;%PATH%"
