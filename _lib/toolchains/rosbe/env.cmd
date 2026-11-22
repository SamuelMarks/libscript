@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration and PATH setup for ReactOS Build Environment (rosbe).
::
:: ## Usage
:: call _lib\toolchains\rosbe\env.cmd

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
if "%ROSBE_VERSION%"=="" (
    if not "%LIBSCRIPT_ROSBE_VERSION%"=="" (
        set "ROSBE_VERSION=%LIBSCRIPT_ROSBE_VERSION%"
    ) else (
        set "ROSBE_VERSION=2.2.1"
    )
)
if /i "%ROSBE_VERSION%"=="latest" set "ROSBE_VERSION=2.2.1"
if "%LIBSCRIPT_ROSBE_ARCH%"=="" set "LIBSCRIPT_ROSBE_ARCH=i386"

set "_ROSBE_BASE=%LIBSCRIPT_ROSBE_INSTALL_DIR%"
if "!_ROSBE_BASE!"=="" set "_ROSBE_BASE=%LIBSCRIPT_HOME%\rosbe\%ROSBE_VERSION%"

for %%D in ("!_ROSBE_BASE!\amd64\bin" "!_ROSBE_BASE!\i386\bin" "!_ROSBE_BASE!\bin") do (
    echo ";!PATH!;" | findstr /I /C:";%%~D;" >nul 2>&1
    if errorlevel 1 set "PATH=%%~D;!PATH!"
)
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\env_base.cmd" "rosbe" "%ROSBE_VERSION%"

endlocal & (
    set "ROSBE_VERSION=%ROSBE_VERSION%"
    set "_ROSBE_BASEDIR=%_ROSBE_BASE%"
    set "ROS_ARCH=%LIBSCRIPT_ROSBE_ARCH%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "PATH=%PATH%"
)
exit /b 0
