@echo off
REM ## Overview
REM Environment variable initialization script for the pyenv component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%PYENV_VERSION%"=="" SET "PYENV_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pyenv\%PYENV_VERSION%\bin;%PATH%"
