@echo off
REM ## Overview
REM Environment variable initialization script for the openbao component.

IF "%OPENBAO_VERSION%"=="" SET "OPENBAO_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\openbao\%OPENBAO_VERSION%\bin;%PATH%"
