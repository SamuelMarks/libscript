@echo off
REM ## Overview
REM Environment variable initialization script for the rye component.

IF "%RYE_VERSION%"=="" SET "RYE_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\rye\%RYE_VERSION%\bin;%PATH%"
