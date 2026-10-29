@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for MySQL on Windows.
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

if "%MYSQL_PORT%"=="" set "MYSQL_PORT=3306"
if "%MYSQL_DATABASE%"=="" set "MYSQL_DATABASE=openedx"
if "%MYSQL_USER%"=="" set "MYSQL_USER=openedx"
if "%MYSQL_VERSION%"=="" set "MYSQL_VERSION=8.4.11"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if exist "%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%\bin" (
    set "_CAND_P=%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%\bin"
    echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
    if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
    set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "mysql"
)

endlocal & set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%" & set "MYSQL_DATABASE=%MYSQL_DATABASE%" & set "MYSQL_PORT=%MYSQL_PORT%" & set "MYSQL_USER=%MYSQL_USER%" & set "MYSQL_VERSION=%MYSQL_VERSION%" & set "PATH=%PATH%"
exit /b 0
