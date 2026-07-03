@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Go on Windows.
::
:: ## Usage
:: Sets `GO_VERSION` and prepends Go to PATH.

:: Environment variables for Windows

if "%GO_VERSION%"=="" set GO_VERSION=latest
if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "PATH=%LIBSCRIPT_BASE_DIR%\go\%GO_VERSION%\bin;%PATH%"
