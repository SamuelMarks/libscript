@echo off
REM ## Overview
REM Environment variable initialization script for the scoop component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%SCOOP_VERSION%"=="" SET "SCOOP_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\scoop\%SCOOP_VERSION%\bin;%PATH%"
