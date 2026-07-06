@echo off
REM ## Overview
REM Environment variable initialization script for the uv component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%UV_VERSION%"=="" SET "UV_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\uv\%UV_VERSION%\bin;%PATH%"
