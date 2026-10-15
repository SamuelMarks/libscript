@echo off
:: # test_remote_db_failure.cmd
::
:: ## Overview
:: Validates the remote DB connection failure recovery mechanism on Windows.
:: Ensures the provision_logical_db script properly catches a bad remote DB IP
:: without attempting to blindly proceed with creation routines that would hang.
::
:: ## Usage
::   call tests\test_remote_db_failure.cmd

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

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

echo ==> Testing Remote DB Connection Failure Handling on Windows...

:: Simulated bad IP address
set "BAD_IP=192.0.2.254"

:: Execute the CMD provisioning script directly, expecting it to handle the failure gracefully
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\provision_logical_db.cmd" --host "!BAD_IP!" --port 3306 --db-name testdb > "%TEMP%\test_remote_db_failure.out" 2>&1

findstr /c:"Attempting creation, but will skip gracefully on permission denied" "%TEMP%\test_remote_db_failure.out" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Script did not attempt graceful fallback on bad remote IP!
    type "%TEMP%\test_remote_db_failure.out"
    exit /b 1
)

echo [PASS] Bad remote IP safely bypassed without crashing!
exit /b 0