@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Node.js on Windows.
::
:: ## Usage
:: Sets `NODEJS_VERSION` and prepends Node.js to PATH.

:: Environment variables for Windows

if "%NODEJS_VERSION%"=="" set NODEJS_VERSION=lts
if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "PATH=%LIBSCRIPT_BASE_DIR%\nodejs\%NODEJS_VERSION%\bin;%PATH%"
