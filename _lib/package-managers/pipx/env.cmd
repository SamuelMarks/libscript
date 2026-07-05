@echo off
REM ## Overview
REM Environment variable initialization script for the pipx component.

IF "%PIPX_VERSION%"=="" SET "PIPX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pipx\%PIPX_VERSION%\bin;%PATH%"
