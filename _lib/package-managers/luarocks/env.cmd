@echo off
REM ## Overview
REM Environment variable initialization script for the luarocks component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%LUAROCKS_VERSION%"=="" SET "LUAROCKS_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\luarocks\%LUAROCKS_VERSION%\bin;%PATH%"
