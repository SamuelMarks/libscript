@echo off
REM ## Overview
REM Environment variable initialization script for the pacman component.

IF "%PACMAN_VERSION%"=="" SET "PACMAN_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\pacman\%PACMAN_VERSION%\bin;%PATH%"
