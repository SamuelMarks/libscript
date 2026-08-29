@echo off
REM ## Overview
REM Environment variable initialization script for the opam component.
REM 
REM ## Usage
REM Call this script to load the environment variables.
set "THIS_FILE=%~f0"

IF "%OPAM_VERSION%"=="" SET "OPAM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\opam\%OPAM_VERSION%\bin;%PATH%"
