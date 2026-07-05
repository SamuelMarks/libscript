@echo off
REM ## Overview
REM Environment variable initialization script for the julia component.

IF "%JULIA_VERSION%"=="" SET "JULIA_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\julia\%JULIA_VERSION%\bin;%PATH%"
