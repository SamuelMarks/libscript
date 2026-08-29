@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for aqua on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for aqua.

:: Windows env stub for aqua
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%AQUA_VERSION%"=="" (
    set "AQUA_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\aqua\%AQUA_VERSION%\bin;%PATH%"
