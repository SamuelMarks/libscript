@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for cygwin on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for cygwin.

:: Windows env stub for cygwin
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CYGWIN_VERSION%"=="" (
    set "CYGWIN_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\cygwin\%CYGWIN_VERSION%\bin;%PATH%"
