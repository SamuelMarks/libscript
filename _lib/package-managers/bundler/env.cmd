@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for bundler on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for bundler.

:: Windows env stub for bundler

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%BUNDLER_VERSION%"=="" (
    set "BUNDLER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\bundler\%BUNDLER_VERSION%\bin;%PATH%"
