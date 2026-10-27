@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for Gunicorn on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

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

if "%GUNICORN_WORKERS%"=="" set "GUNICORN_WORKERS=2"
if "%GUNICORN_BIND%"=="" set "GUNICORN_BIND=0.0.0.0:8000"
if "%GUNICORN_VERSION%"=="" set "GUNICORN_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if exist "%LIBSCRIPT_HOME%\gunicorn\%GUNICORN_VERSION%\Scripts" (
    set "_CAND_P=%LIBSCRIPT_HOME%\gunicorn\%GUNICORN_VERSION%\Scripts"
    echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
    if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
    set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "gunicorn"
)

endlocal & (
    set "GUNICORN_BIND=%GUNICORN_BIND%"
    set "GUNICORN_VERSION=%GUNICORN_VERSION%"
    set "GUNICORN_WORKERS=%GUNICORN_WORKERS%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "PATH=%PATH%"
)
exit /b 0
