@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for fluentbit on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for fluentbit.

:: Windows env stub for fluentbit

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%FLUENTBIT_VERSION%"=="" (
    set "FLUENTBIT_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\fluentbit\%FLUENTBIT_VERSION%\bin;%PATH%"
