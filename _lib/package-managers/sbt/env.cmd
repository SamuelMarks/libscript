@echo off
:: # env.cmd
::
:: ## Overview
:: Environment variable initialization script for the sbt component on Windows.
:: It sets up necessary paths and environment variables required for the component
:: to function correctly within the libscript context.
::
:: ## Usage
:: Call this script to load the environment variables. Do not execute it directly without context.

if "%SBT_VERSION%"=="" set SBT_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)

set "PATH=%LIBSCRIPT_BASE_DIR%\sbt\%SBT_VERSION%\bin;%PATH%"