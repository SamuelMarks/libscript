@echo off
REM ## Overview
REM Environment variable initialization script for the vfox component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%VFOX_VERSION%"=="" SET "VFOX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\vfox\%VFOX_VERSION%\bin;%PATH%"
