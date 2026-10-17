@echo off
:: # cli.cmd
::
:: ## Overview
:: Lifecycle CLI helper for the mesos-marathon-ha HA topology blueprint on Windows.
::
:: ## Usage
:: topologies\mesos-marathon-ha\cli.cmd <up|status|scale|drain|failover|upgrade|down|destroy> [args...]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=status"
if /i "%ACTION%"=="down" set "ACTION=destroy"
call "%LIBSCRIPT_ROOT_DIR%\topologies\engine.cmd" "%ACTION%" "%SCRIPT_DIR%\topology.json" %2 %3 %4
exit /b %errorlevel%

:: ## help
:: Prints usage help for cli.cmd.
:help
echo Usage: cli.cmd ^<up^|status^|scale^|drain^|failover^|upgrade^|down^|destroy^> [args...]
exit /b 0
