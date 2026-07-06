@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for core on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for core.

:: Windows env stub for core

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CORE_VERSION%"=="" (
    set "CORE_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\core\%CORE_VERSION%\bin;%PATH%"
