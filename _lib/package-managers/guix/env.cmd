@echo off
REM ## Overview
REM Environment variable initialization script for the guix component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%GUIX_VERSION%"=="" SET "GUIX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%GUIX_VERSION%\bin;%PATH%"
