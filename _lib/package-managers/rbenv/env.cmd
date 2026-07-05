@echo off
REM ## Overview
REM Environment variable initialization script for the rbenv component.

IF "%RBENV_VERSION%"=="" SET "RBENV_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\rbenv\%RBENV_VERSION%\bin;%PATH%"
