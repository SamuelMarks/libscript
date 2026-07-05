@echo off
REM ## Overview
REM Environment variable initialization script for the yarn component.

IF "%YARN_VERSION%"=="" SET "YARN_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\yarn\%YARN_VERSION%\bin;%PATH%"
