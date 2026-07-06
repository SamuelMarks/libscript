@echo off
REM ## Overview
REM Environment variable initialization script for the rustup component.
REM 
REM ## Usage
REM Call this script to load the environment variables.

IF "%RUSTUP_VERSION%"=="" SET "RUSTUP_VERSION=latest"
SET "PATH=%LIBSCRIPT_HOME%\rustup\%RUSTUP_VERSION%\bin;%PATH%"
