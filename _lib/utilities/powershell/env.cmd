@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for powershell on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for powershell.

:: Windows env stub for powershell

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%POWERSHELL_VERSION%"=="" (
    set "POWERSHELL_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\powershell\%POWERSHELL_VERSION%\bin;%PATH%"
