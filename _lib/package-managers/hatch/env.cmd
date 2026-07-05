@echo off
REM ## Overview
REM Environment variable initialization script for the hatch component.

IF "%HATCH_VERSION%"=="" SET "HATCH_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%HATCH_VERSION%\bin;%PATH%"
