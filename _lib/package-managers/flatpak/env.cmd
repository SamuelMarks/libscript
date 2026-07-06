@echo off
REM ## Overview
REM Environment variable initialization script for the flatpak component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%FLATPAK_VERSION%"=="" SET "FLATPAK_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%FLATPAK_VERSION%\bin;%PATH%"
