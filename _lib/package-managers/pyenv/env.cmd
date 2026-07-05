@echo off
REM ## Overview
REM Environment variable initialization script for the pyenv component.

IF "%PYENV_VERSION%"=="" SET "PYENV_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pyenv\%PYENV_VERSION%\bin;%PATH%"
