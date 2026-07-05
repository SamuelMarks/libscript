@echo off
REM ## Overview
REM Environment variable initialization script for the luarocks component.

IF "%LUAROCKS_VERSION%"=="" SET "LUAROCKS_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\luarocks\%LUAROCKS_VERSION%\bin;%PATH%"
