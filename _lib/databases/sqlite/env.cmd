@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for SQLite on Windows.
:: Resolves the active SQLite prefix and prepends its bin directory to PATH.
::
:: ## Usage
:: call _lib\databases\sqlite\env.cmd

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
if "%SQLITE_VERSION%"=="" set "SQLITE_VERSION=default"
set "SQLITE_PREFIX=%LIBSCRIPT_HOME%\sqlite\%SQLITE_VERSION%"
if "%SQLITE_PATH%"=="" set "SQLITE_PATH=%SQLITE_PREFIX%\sqlite.db"
for %%P in ("%LIBSCRIPT_HOME%\sqlite\default\bin" "%LIBSCRIPT_HOME%\sqlite\%SQLITE_VERSION%\bin") do (
    set "_CAND_P=%%~P"
    echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
    if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
)
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "sqlite" "%SQLITE_VERSION%"

endlocal & (
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "SQLITE_VERSION=%SQLITE_VERSION%"
    set "SQLITE_PREFIX=%SQLITE_PREFIX%"
    set "SQLITE_PATH=%SQLITE_PATH%"
    set "PATH=%PATH%"
)
exit /b 0
