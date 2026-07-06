@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for postgres on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for postgres.

:: Windows env stub for postgres

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%POSTGRES_VERSION%"=="" (
    set "POSTGRES_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\postgres\%POSTGRES_VERSION%\bin;%PATH%"
