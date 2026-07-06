@echo off
REM ## Overview
REM Environment variable initialization script for the krew component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%KREW_VERSION%"=="" SET "KREW_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\krew\%KREW_VERSION%\bin;%PATH%"
