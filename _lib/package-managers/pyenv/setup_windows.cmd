@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for pyenv on Windows.
:: Prepares and configures pyenv on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript pyenv installation on Windows.

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

where pyenv >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "%USERPROFILE%\.pyenv\pyenv-win\bin\pyenv.bat" exit /b 0

where choco >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing pyenv-win via pkg_mgr...
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco pyenv-win
    if not errorlevel 1 exit /b 0
)

echo Installing pyenv-win via cached bootstrap script...
set "_PYENV_PS1=%TEMP%\install-pyenv-win.ps1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" "!_PYENV_PS1!"
if exist "!_PYENV_PS1!" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!_PYENV_PS1!"
    del /f /q "!_PYENV_PS1!" >nul 2>&1
)

if exist "%USERPROFILE%\.pyenv\pyenv-win\bin\pyenv.bat" (
    echo pyenv-win installed successfully.
    exit /b 0
)

where pyenv >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Failed to install pyenv.
exit /b 1
