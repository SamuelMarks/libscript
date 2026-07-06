@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for utils on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for utils.

:: Windows env stub for utils

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%UTILS_VERSION%"=="" (
    set "UTILS_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\utils\%UTILS_VERSION%\bin;%PATH%"
