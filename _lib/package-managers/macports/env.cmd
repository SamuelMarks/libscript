@echo off
REM ## Overview
REM Environment variable initialization script for the macports component.

IF "%MACPORTS_VERSION%"=="" SET "MACPORTS_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\macports\%MACPORTS_VERSION%\bin;%PATH%"
