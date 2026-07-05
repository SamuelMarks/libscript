@echo off
REM ## Overview
REM Environment variable initialization script for the eopkg component.

IF "%EOPKG_VERSION%"=="" SET "EOPKG_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%EOPKG_VERSION%\bin;%PATH%"
