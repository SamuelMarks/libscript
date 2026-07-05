@echo off
REM ## Overview
REM Environment variable initialization script for the helm component.

IF "%HELM_VERSION%"=="" SET "HELM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%${COMP}\%HELM_VERSION%\bin;%PATH%"
