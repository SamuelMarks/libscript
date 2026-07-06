@echo off
REM ## Overview
REM Environment variable initialization script for the pub component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%PUB_VERSION%"=="" SET "PUB_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pub\%PUB_VERSION%\bin;%PATH%"
