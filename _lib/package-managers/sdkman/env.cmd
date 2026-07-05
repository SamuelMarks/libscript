@echo off
REM ## Overview
REM Environment variable initialization script for the sdkman component.

IF "%SDKMAN_VERSION%"=="" SET "SDKMAN_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\sdkman\%SDKMAN_VERSION%\bin;%PATH%"
