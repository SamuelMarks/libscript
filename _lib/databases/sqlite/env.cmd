@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for sqlite on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for sqlite.

:: Windows env stub for sqlite
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%SQLITE_VERSION%"=="" (
    set "SQLITE_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\sqlite\%SQLITE_VERSION%\bin;%PATH%"
