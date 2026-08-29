@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for dash on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for dash.

:: Windows env stub for dash
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%DASH_VERSION%"=="" (
    set "DASH_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\dash\%DASH_VERSION%\bin;%PATH%"
