@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Generic uninstallation handler for rosbe isolated version directories on Windows.
::
:: ## Usage
:: _lib\toolchains\rosbe\uninstall_generic.cmd

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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%ROSBE_VERSION%"=="" set "ROSBE_VERSION=2.2.1"
if /i "%ROSBE_VERSION%"=="latest" set "ROSBE_VERSION=2.2.1"
set "TARGET_INSTALL_DIR=%LIBSCRIPT_ROSBE_INSTALL_DIR%"
if "!TARGET_INSTALL_DIR!"=="" set "TARGET_INSTALL_DIR=%LIBSCRIPT_HOME%\rosbe\%ROSBE_VERSION%"
if exist "!TARGET_INSTALL_DIR!" rmdir /s /q "!TARGET_INSTALL_DIR!"
if exist "%LIBSCRIPT_HOME%\bin\rosbe.cmd" del /f /q "%LIBSCRIPT_HOME%\bin\rosbe.cmd" >nul 2>&1
echo [OK] Uninstalled rosbe %ROSBE_VERSION%.
exit /b 0
