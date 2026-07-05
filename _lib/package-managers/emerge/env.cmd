@echo off
REM ## Overview
REM Environment variable initialization script for the emerge component.

IF "%EMERGE_VERSION%"=="" SET "EMERGE_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\emerge\%EMERGE_VERSION%\bin;%PATH%"
