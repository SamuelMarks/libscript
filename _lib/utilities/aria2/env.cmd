@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for aria2 on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for aria2.

:: Windows env stub for aria2
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%ARIA2_VERSION%"=="" (
    set "ARIA2_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\aria2\%ARIA2_VERSION%\bin;%PATH%"
