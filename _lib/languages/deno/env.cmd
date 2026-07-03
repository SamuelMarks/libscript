@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Deno on Windows.
::
:: ## Usage
:: Sets `DENO_VERSION` and prepends Deno to PATH.

if "%DENO_VERSION%"=="" set DENO_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)

set "PATH=%LIBSCRIPT_BASE_DIR%\deno\%DENO_VERSION%\bin;%PATH%"