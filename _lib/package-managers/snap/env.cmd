@echo off
REM ## Overview
REM Environment variable initialization script for the snap component.

IF "%SNAP_VERSION%"=="" SET "SNAP_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\snap\%SNAP_VERSION%\bin;%PATH%"
