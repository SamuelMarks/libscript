@echo off
REM ## Overview
REM Environment variable initialization script for the stack component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%STACK_VERSION%"=="" SET "STACK_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\stack\%STACK_VERSION%\bin;%PATH%"
