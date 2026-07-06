@echo off
REM ## Overview
REM Environment variable initialization script for the mamba component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%MAMBA_VERSION%"=="" SET "MAMBA_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\mamba\%MAMBA_VERSION%\bin;%PATH%"
