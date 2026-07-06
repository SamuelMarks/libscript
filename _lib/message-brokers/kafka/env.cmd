@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for kafka on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for kafka.

:: Windows env stub for kafka

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%KAFKA_VERSION%"=="" (
    set "KAFKA_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\kafka\%KAFKA_VERSION%\bin;%PATH%"
