@echo off
REM ## Overview
REM Environment variable initialization script for the pip component.

IF "%PIP_VERSION%"=="" SET "PIP_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pip\%PIP_VERSION%\bin;%PATH%"
