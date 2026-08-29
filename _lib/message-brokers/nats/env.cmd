@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for nats on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for nats.

:: Windows env stub for nats
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%NATS_VERSION%"=="" (
    set "NATS_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\nats\%NATS_VERSION%\bin;%PATH%"
