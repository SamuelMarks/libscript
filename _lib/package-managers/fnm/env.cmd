@echo off
REM ## Overview
REM Environment variable initialization script for the fnm component.

IF "%FNM_VERSION%"=="" SET "FNM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%FNM_VERSION%\bin;%PATH%"
