@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for mongodb on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for mongodb.

:: Windows env stub for mongodb
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%MONGODB_VERSION%"=="" (
    set "MONGODB_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\mongodb\%MONGODB_VERSION%\bin;%PATH%"
