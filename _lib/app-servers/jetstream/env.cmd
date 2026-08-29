@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for jetstream on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for jetstream.

:: Windows env stub for jetstream
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%JETSTREAM_VERSION%"=="" (
    set "JETSTREAM_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\jetstream\%JETSTREAM_VERSION%\bin;%PATH%"
