@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Python on Windows.
::
:: ## Usage
:: Sets `PYTHON_VERSION` and `PYTHON_VENV`, adding them to PATH.

if "%PYTHON_VERSION%"=="" set PYTHON_VERSION=3.11.9
if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "PATH=%LIBSCRIPT_BASE_DIR%\python\%PYTHON_VERSION%\bin;%LIBSCRIPT_BASE_DIR%\python\%PYTHON_VERSION%\bin;%PATH%"

if not "%PYTHON_VENV%"=="" (
    set "PATH=%PYTHON_VENV%\Scripts;%PATH%"
    set "VIRTUAL_ENV=%PYTHON_VENV%"
)