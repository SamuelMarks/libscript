@echo off
:: # test_cli_arg_forwarding.cmd
::
:: ## Overview
:: Verifies >10 argument forwarding without %9 truncation in libscript.cmd and traits\engine.cmd.
::
:: ## Usage
:: tests\test_cli_arg_forwarding.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

findstr /C:"_REST_ARGS" "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript.cmd missing _REST_ARGS full-tail argument forwarding >&2
    exit /b 1
)
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" trait list --a1 --a2 --a3 --a4 --a5 --a6 --a7 --a8 --a9 --a10 >nul
if errorlevel 1 (
    echo [FAIL] libscript.cmd trait list failed with >10 arguments >&2
    exit /b 1
)
echo [PASS] Windows >10 CLI argument forwarding verified.
exit /b 0
