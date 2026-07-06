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
set "PYTHONHOME=%LIBSCRIPT_BASE_DIR%\python\%PYTHON_VERSION%"
set "PATH=%PYTHONHOME%\bin;%PYTHONHOME%\Scripts;%PATH%"

:: In cmd we can't easily extract major.minor, but Python natively searches lib\site-packages in Windows.
set "PYTHONPATH=%PYTHONHOME%\Lib\site-packages;%PYTHONPATH%"

if not "%PYTHON_VENV%"=="" (
    set "PATH=%PYTHON_VENV%\Scripts;%PATH%"
    set "VIRTUAL_ENV=%PYTHON_VENV%"
    set "PYTHONHOME="
)