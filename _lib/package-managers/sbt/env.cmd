@echo off
REM ## Overview
REM Environment variable initialization script for the sbt component.

IF "%SBT_VERSION%"=="" SET "SBT_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\sbt\%SBT_VERSION%\bin;%PATH%"
