@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for just on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for just.

:: Windows env stub for just
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%JUST_VERSION%"=="" (
    set "JUST_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\just\%JUST_VERSION%\bin;%PATH%"
