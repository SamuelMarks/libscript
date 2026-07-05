@echo off
REM ## Overview
REM Environment variable initialization script for the nix component.

IF "%NIX_VERSION%"=="" SET "NIX_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\nix\%NIX_VERSION%\bin;%PATH%"
