@echo off
REM ## Overview
REM Environment variable initialization script for the mix component.

IF "%MIX_VERSION%"=="" SET "MIX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\mix\%MIX_VERSION%\bin;%PATH%"
