@echo off
REM ## Overview
REM Environment variable initialization script for the gem component.

IF "%GEM_VERSION%"=="" SET "GEM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%GEM_VERSION%\bin;%PATH%"
