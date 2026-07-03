@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Bun on Windows.
::
:: ## Usage
:: Normally sets up defaults and prepends Bun to PATH.

if "%BUN_VERSION%"=="" set BUN_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)

set "PATH=%LIBSCRIPT_BASE_DIR%\bun\%BUN_VERSION%\bin;%PATH%"