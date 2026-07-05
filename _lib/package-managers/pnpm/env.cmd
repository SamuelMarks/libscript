@echo off
REM ## Overview
REM Environment variable initialization script for the pnpm component.

IF "%PNPM_VERSION%"=="" SET "PNPM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pnpm\%PNPM_VERSION%\bin;%PATH%"
