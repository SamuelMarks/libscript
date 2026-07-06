@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for brew on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for brew.

:: Windows env stub for brew

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%BREW_VERSION%"=="" (
    set "BREW_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\brew\%BREW_VERSION%\bin;%PATH%"
