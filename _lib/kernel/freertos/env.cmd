@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration and PATH setup for FreeRTOS kernel recipe.
::
:: ## Usage
:: call _lib\kernel\freertos\env.cmd

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
if "%FREERTOS_VERSION%"=="" set "FREERTOS_VERSION=11.1.0"
if "%FREERTOS_KERNEL_PATH%"=="" set "FREERTOS_KERNEL_PATH=%LIBSCRIPT_HOME%\freertos\%FREERTOS_VERSION%"

if exist "%FREERTOS_KERNEL_PATH%\bin" (
    echo ";!PATH!;" | findstr /I /C:";%FREERTOS_KERNEL_PATH%\bin;" >nul 2>&1
    if errorlevel 1 set "PATH=%FREERTOS_KERNEL_PATH%\bin;!PATH!"
)
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\env_base.cmd" "freertos" "%FREERTOS_VERSION%"

endlocal & (
    set "FREERTOS_VERSION=%FREERTOS_VERSION%"
    set "FREERTOS_KERNEL_PATH=%FREERTOS_KERNEL_PATH%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "PATH=%PATH%"
)
exit /b 0
