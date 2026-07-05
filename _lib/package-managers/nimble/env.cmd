@echo off
REM ## Overview
REM Environment variable initialization script for the nimble component.

IF "%NIMBLE_VERSION%"=="" SET "NIMBLE_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\nimble\%NIMBLE_VERSION%\bin;%PATH%"
