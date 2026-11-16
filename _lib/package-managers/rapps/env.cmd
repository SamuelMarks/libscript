@echo off
:: # env.cmd
::
:: ## Overview
:: Windows and ReactOS environment configuration and PATH setup for rapps.
::
:: ## Usage
:: call _lib\package-managers\rapps\env.cmd

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
if "%RAPPS_VERSION%"=="" (
    if not "%LIBSCRIPT_RAPPS_VERSION%"=="" (
        set "RAPPS_VERSION=%LIBSCRIPT_RAPPS_VERSION%"
    ) else (
        set "RAPPS_VERSION=0.4.16"
    )
)
if /i "%RAPPS_VERSION%"=="latest" set "RAPPS_VERSION=0.4.16"

set "_CAND_P=%LIBSCRIPT_HOME%\rapps\%RAPPS_VERSION%\bin"
if "%LIBSCRIPT_RAPPS_DB_DIR%"=="" (
    set "LIBSCRIPT_RAPPS_DB_DIR=%LIBSCRIPT_HOME%\rapps\%RAPPS_VERSION%\db"
)
echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "rapps" "%RAPPS_VERSION%"

endlocal & (
    set "RAPPS_VERSION=%RAPPS_VERSION%"
    set "LIBSCRIPT_RAPPS_DB_DIR=%LIBSCRIPT_RAPPS_DB_DIR%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "PATH=%PATH%"
)
exit /b 0
