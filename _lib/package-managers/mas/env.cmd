@echo off
REM ## Overview
REM Environment variable initialization script for the mas component.

IF "%MAS_VERSION%"=="" SET "MAS_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\mas\%MAS_VERSION%\bin;%PATH%"
