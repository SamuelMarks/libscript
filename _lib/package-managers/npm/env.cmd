@echo off
REM ## Overview
REM Environment variable initialization script for the npm component.

IF "%NPM_VERSION%"=="" SET "NPM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\npm\%NPM_VERSION%\bin;%PATH%"
