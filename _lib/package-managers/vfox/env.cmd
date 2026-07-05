@echo off
REM ## Overview
REM Environment variable initialization script for the vfox component.

IF "%VFOX_VERSION%"=="" SET "VFOX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\vfox\%VFOX_VERSION%\bin;%PATH%"
