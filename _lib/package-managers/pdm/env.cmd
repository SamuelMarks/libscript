@echo off
REM ## Overview
REM Environment variable initialization script for the pdm component.

IF "%PDM_VERSION%"=="" SET "PDM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pdm\%PDM_VERSION%\bin;%PATH%"
