@echo off
:: # env.cmd
::
:: ## Overview
:: Environment variable initialization script for the cmake component on Windows.
:: It sets up necessary paths and environment variables required for the component
:: to function correctly within the libscript context.
::
:: ## Usage
:: Call this script to load the environment variables. Do not execute it directly without context.
set "THIS_FILE=%~f0"

if "%CMAKE_VERSION%"=="" set CMAKE_VERSION=latest
if "%CMAKE_VERSION%"=="latest" set CMAKE_VERSION=3.31.2
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set PATH=%LIBSCRIPT_HOME%\cmake\%CMAKE_VERSION%\bin;%PATH%
