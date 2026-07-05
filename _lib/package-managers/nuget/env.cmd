@echo off
REM ## Overview
REM Environment variable initialization script for the nuget component.

IF "%NUGET_VERSION%"=="" SET "NUGET_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\nuget\%NUGET_VERSION%\bin;%PATH%"
