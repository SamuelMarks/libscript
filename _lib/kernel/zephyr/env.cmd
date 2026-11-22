@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration and PATH setup for Zephyr RTOS kernel recipe.
::
:: ## Usage
:: call _lib\kernel\zephyr\env.cmd

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
if "%ZEPHYR_VERSION%"=="" set "ZEPHYR_VERSION=3.7.0"
if "%ZEPHYR_BASE%"=="" set "ZEPHYR_BASE=%LIBSCRIPT_HOME%\zephyr\%ZEPHYR_VERSION%"
if "%ZEPHYR_TOOLCHAIN_VARIANT%"=="" set "ZEPHYR_TOOLCHAIN_VARIANT=zephyr"
if "%ZEPHYR_SDK_INSTALL_DIR%"=="" set "ZEPHYR_SDK_INSTALL_DIR=%LIBSCRIPT_HOME%\zephyr-sdk\0.17.0"

set "_CAND_P=%ZEPHYR_BASE%\bin"
if exist "!_CAND_P!" (
    echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
    if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
)
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\env_base.cmd" "zephyr" "%ZEPHYR_VERSION%"

endlocal & (
    set "ZEPHYR_VERSION=%ZEPHYR_VERSION%"
    set "ZEPHYR_BASE=%ZEPHYR_BASE%"
    set "ZEPHYR_TOOLCHAIN_VARIANT=%ZEPHYR_TOOLCHAIN_VARIANT%"
    set "ZEPHYR_SDK_INSTALL_DIR=%ZEPHYR_SDK_INSTALL_DIR%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "PATH=%PATH%"
)
exit /b 0
