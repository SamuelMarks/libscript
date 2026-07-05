@echo off
REM ## Overview
REM Environment variable initialization script for the paru component.

IF "%PARU_VERSION%"=="" SET "PARU_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\paru\%PARU_VERSION%\bin;%PATH%"
