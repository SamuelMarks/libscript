@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for the Unified C Compiler Router (cc) on Windows.
::
:: ## Usage
:: call _lib\languages\cc\env.cmd

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
if "%SCRIPT_DIR:~-1%"=="\\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

if "%CC_INSTALL_METHOD%"=="" set "CC_INSTALL_METHOD=system"
if "%CC_VERSION%"=="" set "CC_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if not "%CC_BACKEND%"=="" if not "%CC_BACKEND%"=="default" (
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\languages\%CC_BACKEND%\env.cmd" (
        call "%LIBSCRIPT_ROOT_DIR%\_lib\languages\%CC_BACKEND%\env.cmd"
    )
)
endlocal & set "PATH=%LIBSCRIPT_HOME%\cc\%CC_VERSION%\bin;%PATH%"
exit /b 0
