@echo off
REM ## Overview
REM Environment variable initialization script for the spack component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%SPACK_VERSION%"=="" SET "SPACK_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\spack\%SPACK_VERSION%\bin;%PATH%"
