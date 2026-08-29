@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for conda on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for conda.

:: Windows env stub for conda
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CONDA_VERSION%"=="" (
    set "CONDA_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\conda\%CONDA_VERSION%\bin;%PATH%"
