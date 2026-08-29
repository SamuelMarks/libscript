@echo off
REM ## Overview
REM Environment variable initialization script for the vcpkg component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%VCPKG_VERSION%"=="" SET "VCPKG_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\vcpkg\%VCPKG_VERSION%\bin;%PATH%"
