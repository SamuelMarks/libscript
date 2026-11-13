@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration for upstream reference `libtpu` (`LIBTPU_REFERENCE_DIR`, `LIBTPU_REFERENCE_SO`, `LIBTPU_REFERENCE_SDK_SO`).
::
:: ## Usage
:: call _lib\runtimes\libtpu\env.cmd

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

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%LIBTPU_VERSION%"=="" (
    set "LIBTPU_VERSION=0.0.52"
)
set "_LT_BASE=%LIBSCRIPT_HOME%\libtpu\%LIBTPU_VERSION%"
set "_LT_SO=%LIBTPU_SO_PATH%"
if "!_LT_SO!"=="" set "_LT_SO=!_LT_BASE!\x86_64\libtpu.so"
set "_LT_SDK=%LIBTPU_SDK_SO_PATH%"
if "!_LT_SDK!"=="" set "_LT_SDK=!_LT_BASE!\x86_64\sdk.so"

set "_CAND_P=!_LT_BASE!\bin"
echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "libtpu" "%LIBTPU_VERSION%"

endlocal & (
    set "LIBTPU_VERSION=%LIBTPU_VERSION%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "LIBTPU_REFERENCE_DIR=%_LT_BASE%"
    set "LIBTPU_REFERENCE_SO=%_LT_SO%"
    set "LIBTPU_REFERENCE_SDK_SO=%_LT_SDK%"
    set "PATH=%PATH%"
)
exit /b 0
