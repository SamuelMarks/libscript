@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Python on Windows.
::
:: ## Usage
:: Sets `PYTHON_VERSION` and `PYTHON_VENV`, adding them to PATH.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

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