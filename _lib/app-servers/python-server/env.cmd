@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for python-server on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for python-server.

:: Windows env stub for python-server
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%PYTHON_SERVER_VERSION%"=="" (
    set "PYTHON_SERVER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\python-server\%PYTHON_SERVER_VERSION%\bin;%PATH%"
