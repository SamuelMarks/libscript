@echo off
REM ## Overview
REM Environment variable initialization script for the minio component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%MINIO_VERSION%"=="" SET "MINIO_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\minio\%MINIO_VERSION%\bin;%PATH%"
