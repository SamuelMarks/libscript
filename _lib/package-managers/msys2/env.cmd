@echo off
REM ## Overview
REM Environment variable initialization script for the msys2 component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%MSYS2_VERSION%"=="" SET "MSYS2_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\msys2\%MSYS2_VERSION%\bin;%PATH%"
