@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Ruby on Windows.
::
:: ## Usage
:: Sets `RUBY_VERSION` and prepends Ruby to PATH.

if "%RUBY_VERSION%"=="" set RUBY_VERSION=latest
if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "PATH=%LIBSCRIPT_BASE_DIR%\ruby\%RUBY_VERSION%\bin;%PATH%"