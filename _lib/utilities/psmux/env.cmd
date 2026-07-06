@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for psmux on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for psmux.

:: Windows env stub for psmux

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%PSMUX_VERSION%"=="" (
    set "PSMUX_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\psmux\%PSMUX_VERSION%\bin;%PATH%"
