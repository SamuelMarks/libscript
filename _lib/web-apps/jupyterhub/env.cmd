@echo off
:: # env.cmd
::
:: ## Overview
:: Defines environment variables and configurations for the JupyterHub data science platform stack.
:: 
:: ## Usage
:: Source or call this script to configure the environment for jupyterhub.

:: Environment variables for Windows
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

if "%PYTHON_VERSION%"=="" set "PYTHON_VERSION=3.10"
if "%JUPYTERHUB_NOTEBOOK_DIR%"=="" set "JUPYTERHUB_NOTEBOOK_DIR=C:\notebooks"
if "%JUPYTERHUB_IP%"=="" set "JUPYTERHUB_IP=127.0.0.1"
if "%JUPYTERHUB_PORT%"=="" set "JUPYTERHUB_PORT=8888"

endlocal & (
    set "JUPYTERHUB_IP=%JUPYTERHUB_IP%"
    set "JUPYTERHUB_NOTEBOOK_DIR=%JUPYTERHUB_NOTEBOOK_DIR%"
    set "JUPYTERHUB_PORT=%JUPYTERHUB_PORT%"
    set "PYTHON_VERSION=%PYTHON_VERSION%"
)
exit /b 0
