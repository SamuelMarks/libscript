@echo off
REM ## Overview
REM Environment variable initialization script for the stack component.

IF "%STACK_VERSION%"=="" SET "STACK_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\stack\%STACK_VERSION%\bin;%PATH%"
