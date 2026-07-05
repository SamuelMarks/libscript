@echo off
REM ## Overview
REM Environment variable initialization script for the krew component.

IF "%KREW_VERSION%"=="" SET "KREW_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\krew\%KREW_VERSION%\bin;%PATH%"
