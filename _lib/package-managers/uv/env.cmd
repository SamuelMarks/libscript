@echo off
REM ## Overview
REM Environment variable initialization script for the uv component.

IF "%UV_VERSION%"=="" SET "UV_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\uv\%UV_VERSION%\bin;%PATH%"
