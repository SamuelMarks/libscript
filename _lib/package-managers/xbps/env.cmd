@echo off
REM ## Overview
REM Environment variable initialization script for the xbps component.

IF "%XBPS_VERSION%"=="" SET "XBPS_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\xbps\%XBPS_VERSION%\bin;%PATH%"
