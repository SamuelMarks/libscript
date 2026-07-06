@echo off
REM ## Overview
REM Environment variable initialization script for the pkg component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%PKG_VERSION%"=="" SET "PKG_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pkg\%PKG_VERSION%\bin;%PATH%"
