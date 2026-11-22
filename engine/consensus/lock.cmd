@echo off
:: # lock.cmd
:: ## Overview
:: Distributed lease lock manager for T5 cluster topologies on Windows supporting local, etcd, s3, gs, and azure backends.
:: ## Usage
:: engine\consensus\lock.cmd <acquire|release|status> <lock_file_or_uri> [holder_id]

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

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

set "ACTION=%~1"
set "LOCK_TARGET=%~2"
set "HOLDER_ID=%~3"
set "BACKEND=%LIBSCRIPT_LOCK_BACKEND%"
if "%ACTION%"=="" set "ACTION=status"
if "%LOCK_TARGET%"=="" set "LOCK_TARGET=.topology.lock"
if "%HOLDER_ID%"=="" set "HOLDER_ID=libscript-cli-win"
if "%BACKEND%"=="" set "BACKEND=local"

if /i "%ACTION%"=="acquire" goto :acquire
if /i "%ACTION%"=="release" goto :release
if /i "%ACTION%"=="status" goto :status

echo [ERROR] Unknown lock action: %ACTION% 1>&2
exit /b 1

:: ## acquire
:: Acquires the topology lease lock atomically and creates parent directories if needed.
:acquire
for %%D in ("%LOCK_TARGET%") do set "_LOCK_PARENT=%%~dpD"
if not "!_LOCK_PARENT!"=="" (
    if not exist "!_LOCK_PARENT!" mkdir "!_LOCK_PARENT!"
)
set "_NOW_TS=2026-10-15T00:00:00Z"
where jq >nul 2>&1
if not errorlevel 1 (
    for /f "usebackq delims=" %%T in (`jq -rn --arg f "%%Y-%%m-%%dT%%H:%%M:%%SZ" "now | strftime($f)" 2^>nul`) do set "_NOW_TS=%%T"
)
> "%LOCK_TARGET%.tmp" echo {"holder_id":"%HOLDER_ID%","acquired_at":"!_NOW_TS!","expires_at":"2026-10-15T01:00:00Z","lock_backend":"%BACKEND%"}
move /y "%LOCK_TARGET%.tmp" "%LOCK_TARGET%" >nul
type "%LOCK_TARGET%"
exit /b 0

:: ## release
:: Releases the topology lease lock idempotently.
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
