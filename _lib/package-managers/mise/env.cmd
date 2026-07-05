@echo off
REM ## Overview
REM Environment variable initialization script for the mise component.

IF "%MISE_VERSION%"=="" SET "MISE_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\mise\%MISE_VERSION%\bin;%PATH%"
