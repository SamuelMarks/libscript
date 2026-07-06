@echo off
REM ## Overview
REM Environment variable initialization script for the pipx component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%PIPX_VERSION%"=="" SET "PIPX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pipx\%PIPX_VERSION%\bin;%PATH%"
