@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Node.js on Windows.
::
:: ## Usage
:: Sets `NODEJS_VERSION` and prepends Node.js to PATH.

:: Environment variables for Windows
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
if "%NODEJS_VERSION%"=="" set "NODEJS_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "nodejs" "%NODEJS_VERSION%"

set "_NODE_VER_CLEAN=%NODEJS_VERSION%"
if /i "!_NODE_VER_CLEAN:~0,1!"=="v" set "_NODE_VER_CLEAN=!_NODE_VER_CLEAN:~1!"
set "_NODE_BIN=%LIBSCRIPT_BASE_DIR%\nodejs\%NODEJS_VERSION%\bin"
set "_NODE_ROOT=%LIBSCRIPT_BASE_DIR%\nodejs\%NODEJS_VERSION%"
set "_NEW_PATH=!PATH!"
set "_NODE_ADDED=0"
for %%N in ("%ProgramFiles%\nodejs" "%LIBSCRIPT_BASE_DIR%\nodejs\default\bin" "%LIBSCRIPT_BASE_DIR%\nodejs\v!_NODE_VER_CLEAN!\bin" "!_NODE_ROOT!" "!_NODE_BIN!") do (
    if exist "%%~fN" (
        echo ";!_NEW_PATH!;" | findstr /I /C:";%%~fN;" >nul 2>&1
        if errorlevel 1 set "_NEW_PATH=%%~fN;!_NEW_PATH!"
        set "_NODE_ADDED=1"
    )
)
if "!_NODE_ADDED!"=="0" (
    echo ";!_NEW_PATH!;" | findstr /I /C:";!_NODE_BIN!;" >nul 2>&1
    if errorlevel 1 set "_NEW_PATH=!_NODE_BIN!;!_NEW_PATH!"
)

endlocal & (
    set "NODEJS_VERSION=%NODEJS_VERSION%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_BASE_DIR%"
    set "PATH=%_NEW_PATH%"
)
exit /b 0
