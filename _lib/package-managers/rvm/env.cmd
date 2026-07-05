@echo off
REM ## Overview
REM Environment variable initialization script for the rvm component.

IF "%RVM_VERSION%"=="" SET "RVM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\rvm\%RVM_VERSION%\bin;%PATH%"
