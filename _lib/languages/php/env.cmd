@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for PHP on Windows.
::
:: ## Usage
:: Sets `PHP_VERSION` and prepends PHP to PATH.

if "%PHP_VERSION%"=="" set PHP_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)

set "PATH=%LIBSCRIPT_BASE_DIR%\php\%PHP_VERSION%\bin;%PATH%"