@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for iis on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for iis.

:: Windows env stub for iis
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%IIS_VERSION%"=="" (
    set "IIS_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\iis\%IIS_VERSION%\bin;%PATH%"
