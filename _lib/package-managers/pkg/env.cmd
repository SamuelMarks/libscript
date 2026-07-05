@echo off
REM ## Overview
REM Environment variable initialization script for the pkg component.

IF "%PKG_VERSION%"=="" SET "PKG_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pkg\%PKG_VERSION%\bin;%PATH%"
