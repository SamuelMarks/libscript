@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for openrc on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for openrc.

:: Windows env stub for openrc

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%OPENRC_VERSION%"=="" (
    set "OPENRC_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\openrc\%OPENRC_VERSION%\bin;%PATH%"
