@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup module for nodeenv.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
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

if "%ACTION%"=="" set "ACTION=install"
if "%NODEENV_VERSION%"=="" set "NODEENV_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if "%ACTION%"=="install" (
    where nodeenv >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] nodeenv is already installed on the system.
        exit /b 0
    )
    where uv >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing nodeenv via uv...
        uv tool install nodeenv >nul 2>&1 || uv pip install nodeenv
        exit /b 0
    )
    where pipx >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing nodeenv via pipx...
        pipx install nodeenv
        exit /b 0
    )
    where pip >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing nodeenv via pip...
        pip install --user nodeenv
        exit /b 0
    )
    echo [ERROR] Python environment with pip or uv is required to install nodeenv on Windows.
    exit /b 1
) else if "%ACTION%"=="uninstall" (
    where uv >nul 2>&1 && uv tool uninstall nodeenv >nul 2>&1
    where pipx >nul 2>&1 && pipx uninstall nodeenv >nul 2>&1
    where pip >nul 2>&1 && pip uninstall -y nodeenv >nul 2>&1
    exit /b 0
) else if "%ACTION%"=="test" (
    nodeenv --version
    exit /b %ERRORLEVEL%
)

exit /b 0
