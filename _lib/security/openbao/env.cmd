@echo off
REM ## Overview
REM Environment variable initialization script for the openbao component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%OPENBAO_VERSION%"=="" SET "OPENBAO_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\openbao\%OPENBAO_VERSION%\bin;%PATH%"
