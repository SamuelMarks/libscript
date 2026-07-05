@echo off
REM ## Overview
REM Environment variable initialization script for the mamba component.

IF "%MAMBA_VERSION%"=="" SET "MAMBA_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\mamba\%MAMBA_VERSION%\bin;%PATH%"
