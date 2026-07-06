@echo off
REM ## Overview
REM Environment variable initialization script for the xbps component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%XBPS_VERSION%"=="" SET "XBPS_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\xbps\%XBPS_VERSION%\bin;%PATH%"
