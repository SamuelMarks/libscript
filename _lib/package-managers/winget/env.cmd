@echo off
REM ## Overview
REM Environment variable initialization script for the winget component.

IF "%WINGET_VERSION%"=="" SET "WINGET_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\winget\%WINGET_VERSION%\bin;%PATH%"
