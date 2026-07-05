@echo off
REM ## Overview
REM Environment variable initialization script for the vcpkg component.

IF "%VCPKG_VERSION%"=="" SET "VCPKG_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\vcpkg\%VCPKG_VERSION%\bin;%PATH%"
