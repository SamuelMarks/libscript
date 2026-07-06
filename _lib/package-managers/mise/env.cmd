@echo off
REM ## Overview
REM Environment variable initialization script for the mise component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%MISE_VERSION%"=="" SET "MISE_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\mise\%MISE_VERSION%\bin;%PATH%"
