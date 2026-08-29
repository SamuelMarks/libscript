@echo off
REM ## Overview
REM Environment variable initialization script for the nix component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%NIX_VERSION%"=="" SET "NIX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\nix\%NIX_VERSION%\bin;%PATH%"
