@echo off
REM ## Overview
REM Environment variable initialization script for the guix component.

IF "%GUIX_VERSION%"=="" SET "GUIX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%GUIX_VERSION%\bin;%PATH%"
