@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for wait4x on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for wait4x.

:: Windows env stub for wait4x

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%WAIT4X_VERSION%"=="" (
    set "WAIT4X_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\wait4x\%WAIT4X_VERSION%\bin;%PATH%"
