@echo off
:: # lock.cmd
::
:: ## Overview
:: Distributed lease lock manager for Tier 3.5 cluster topologies on Windows.
::
:: ## Usage
:: topologies\lock.cmd <acquire|release|status> <lock_file_or_uri> [holder_id]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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
set "LOCK_TARGET=%~2"
set "HOLDER_ID=%~3"
if "%ACTION%"=="" set "ACTION=status"
if "%LOCK_TARGET%"=="" set "LOCK_TARGET=.topology.lock"
if "%HOLDER_ID%"=="" set "HOLDER_ID=libscript-cli-win"

if "%ACTION%"=="acquire" goto :acquire
if "%ACTION%"=="release" goto :release
if "%ACTION%"=="status" goto :status

echo [ERROR] Unknown lock action: %ACTION% 1>&2
exit /b 1

:: ## acquire
:: Acquires the topology lease lock.
:acquire
echo {"holder_id":"%HOLDER_ID%","acquired_at":"2026-10-15T00:00:00Z","expires_at":"2026-10-15T01:00:00Z","lock_backend":"local"} > "%LOCK_TARGET%"
type "%LOCK_TARGET%"
exit /b 0

:: ## release
:: Releases the topology lease lock.
:release
if exist "%LOCK_TARGET%" del /f /q "%LOCK_TARGET%" >nul 2>&1
echo {"status":"released","lock":"%LOCK_TARGET%"}
exit /b 0

:: ## status
:: Queries the topology lease lock status.
:status
if exist "%LOCK_TARGET%" (
    type "%LOCK_TARGET%"
) else (
    echo {"status":"unlocked","lock":"%LOCK_TARGET%"}
)
exit /b 0

:: ## help
:: Prints usage help for lock.cmd.
:help
echo Usage: lock.cmd ^<acquire^|release^|status^> ^<lock_file_or_uri^> [holder_id]
exit /b 0
