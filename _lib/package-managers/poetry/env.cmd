@echo off
REM ## Overview
REM Environment variable initialization script for the poetry component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%POETRY_VERSION%"=="" SET "POETRY_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\poetry\%POETRY_VERSION%\bin;%PATH%"
