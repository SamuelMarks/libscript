@echo off
REM ## Overview
REM Environment variable initialization script for the yay component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%YAY_VERSION%"=="" SET "YAY_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\yay\%YAY_VERSION%\bin;%PATH%"
