@echo off
REM ## Overview
REM Environment variable initialization script for the poetry component.

IF "%POETRY_VERSION%"=="" SET "POETRY_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\poetry\%POETRY_VERSION%\bin;%PATH%"
