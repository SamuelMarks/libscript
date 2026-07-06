@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for valkey on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for valkey.

:: Windows env stub for valkey

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%VALKEY_VERSION%"=="" (
    set "VALKEY_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\valkey\%VALKEY_VERSION%\bin;%PATH%"
