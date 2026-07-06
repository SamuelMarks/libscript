@echo off
REM ## Overview
REM Environment variable initialization script for the emerge component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%EMERGE_VERSION%"=="" SET "EMERGE_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\emerge\%EMERGE_VERSION%\bin;%PATH%"
