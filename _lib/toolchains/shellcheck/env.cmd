@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration and PATH setup for shellcheck.
::
:: ## Usage
:: call _lib\toolchains\shellcheck\env.cmd

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

if "%SHELLCHECK_VERSION%"=="" (
    set "SHELLCHECK_VERSION=latest"
)

set "_NORM_SC_VER=%SHELLCHECK_VERSION%"
if /i "!_NORM_SC_VER:~0,1!"=="v" (
    if /i not "!_NORM_SC_VER!"=="latest" set "_NORM_SC_VER=!_NORM_SC_VER:~1!"
)

set "_CAND_P=%LIBSCRIPT_HOME%\shellcheck\!_NORM_SC_VER!\bin"
if not exist "!_CAND_P!" (
    if exist "%LIBSCRIPT_HOME%\shellcheck\default\bin" (
        set "_CAND_P=%LIBSCRIPT_HOME%\shellcheck\default\bin"
    )
)
echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "shellcheck" "!_NORM_SC_VER!"

endlocal & (
    set "SHELLCHECK_VERSION=%SHELLCHECK_VERSION%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "PATH=%PATH%"
)
exit /b 0
