@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for choco on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for choco.

:: Windows env stub for choco

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CHOCO_VERSION%"=="" (
    set "CHOCO_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\choco\%CHOCO_VERSION%\bin;%PATH%"
