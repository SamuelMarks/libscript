@echo off
REM ## Overview
REM Environment variable initialization script for the r component.

IF "%R_VERSION%"=="" SET "R_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\r\%R_VERSION%\bin;%PATH%"
