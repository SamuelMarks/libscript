@echo off
REM ## Overview
REM Environment variable initialization script for the yay component.

IF "%YAY_VERSION%"=="" SET "YAY_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\yay\%YAY_VERSION%\bin;%PATH%"
