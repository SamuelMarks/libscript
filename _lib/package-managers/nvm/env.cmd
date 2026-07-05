@echo off
REM ## Overview
REM Environment variable initialization script for the nvm component.

IF "%NVM_VERSION%"=="" SET "NVM_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\nvm\%NVM_VERSION%\bin;%PATH%"
