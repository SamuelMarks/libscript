@echo off
REM ## Overview
REM Environment variable initialization script for the pdm component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%PDM_VERSION%"=="" SET "PDM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pdm\%PDM_VERSION%\bin;%PATH%"
