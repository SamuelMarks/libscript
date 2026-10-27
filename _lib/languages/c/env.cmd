@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for the Unified C Toolchain Router (c) on Windows.
::
:: ## Usage
:: call _lib\languages\c\env.cmd

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

if "%C_INSTALL_METHOD%"=="" set "C_INSTALL_METHOD=system"
if "%C_VERSION%"=="" set "C_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if not "%CC_BACKEND%"=="" if not "%CC_BACKEND%"=="default" (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\languages\%CC_BACKEND%\env.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\%CC_BACKEND%\env.cmd"
    )
)
if "%CC%"=="" (
    for %%B in (cl.exe gcc.exe clang.exe cc.exe) do (
        if "!CC!"=="" (
            for /f "delims=" %%F in ('where %%B 2^>nul') do if "!CC!"=="" set "CC=%%F"
        )
    )
)
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "c" "%C_VERSION%" "%LIBSCRIPT_HOME%\c\%C_VERSION%\bin"
endlocal & (
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "C_VERSION=%C_VERSION%"
    set "C_INSTALL_METHOD=%C_INSTALL_METHOD%"
    set "CC=%CC%"
    set "PATH=%PATH%"
)
exit /b 0
