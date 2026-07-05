@echo off
REM ## Overview
REM Environment variable initialization script for the zypper component.

IF "%ZYPPER_VERSION%"=="" SET "ZYPPER_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\zypper\%ZYPPER_VERSION%\bin;%PATH%"
