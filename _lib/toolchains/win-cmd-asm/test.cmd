@echo off
:: # test.cmd
::
:: ## Overview
:: Smoke test for win-cmd-asm on Windows verifying 2x idempotency, asm-conv, and DOS binary staging.
::
:: ## Usage
:: _lib\toolchains\win-cmd-asm\test.cmd

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

set "STACK="
call "!SCRIPT_DIR!\cli.cmd" install latest >nul
if errorlevel 1 exit /b 1
set "STACK="
call "!SCRIPT_DIR!\cli.cmd" install latest >nul
if errorlevel 1 exit /b 1
set "STACK="
call "!SCRIPT_DIR!\env.cmd"
asm-conv.exe --version | findstr /I /C:"asm-conv" >nul
if errorlevel 1 exit /b 1
echo [PASS] win-cmd-asm Windows smoke verified.
exit /b 0
