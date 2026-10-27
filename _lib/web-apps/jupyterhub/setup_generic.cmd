@echo off
:: # setup.cmd
::
:: ## Overview
:: Orchestrates the setup and installation process for the JupyterHub data science platform stack on Windows.
:: Installs jupyterhub via Python and configurable-http-proxy via npm if available.
:: 
:: ## Usage
:: Execute this script to install and configure jupyterhub on the local system.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
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

where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is required for JupyterHub.
    exit /b 1
)

echo [INFO] Installing JupyterHub via Python pip...
python -m pip install --quiet --upgrade jupyterhub
if errorlevel 1 (
    echo [ERROR] Failed to install JupyterHub via pip.
    exit /b 1
)

set "BIN_DIR=%USERPROFILE%\.libscript\jupyterhub\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"

where npm >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Installing configurable-http-proxy into isolated prefix...
    call npm install --prefix "%USERPROFILE%\.libscript\jupyterhub\latest" configurable-http-proxy >nul 2>&1
)

(
    echo @echo off
    echo python -m jupyterhub %%*
) > "!BIN_DIR!\jupyterhub.cmd"

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\jupyterhub.cmd" "%USERPROFILE%\.local\bin\jupyterhub.cmd" >nul 2>&1

echo [INFO] JupyterHub setup completed successfully.
exit /b 0
