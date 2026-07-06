@echo off
REM ## Overview
REM Environment variable initialization script for the pip component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%PIP_VERSION%"=="" SET "PIP_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pip\%PIP_VERSION%\bin;%PATH%"
