@echo off
REM ## Overview
REM Environment variable initialization script for the scoop component.

IF "%SCOOP_VERSION%"=="" SET "SCOOP_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\scoop\%SCOOP_VERSION%\bin;%PATH%"
