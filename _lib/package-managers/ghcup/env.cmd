@echo off
REM ## Overview
REM Environment variable initialization script for the ghcup component.

IF "%GHCUP_VERSION%"=="" SET "GHCUP_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%GHCUP_VERSION%\bin;%PATH%"
