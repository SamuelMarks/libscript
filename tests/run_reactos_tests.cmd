@echo off
:: # run_reactos_tests.cmd
::
:: ## Overview
:: Runs all standalone ReactOS distribution verification tests on Windows.
::
:: ## Usage
:: tests\run_reactos_tests.cmd

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

set "STACK=" & call "!SCRIPT_DIR!\reactos_boot_test.cmd" || exit /b 1
set "STACK=" & call "!SCRIPT_DIR!\reactos_gui_smoke_test.cmd" || exit /b 1
set "STACK=" & call "!SCRIPT_DIR!\reactos_network_smoke_test.cmd" || exit /b 1
set "STACK=" & call "!SCRIPT_DIR!\reactos_vagrant_box_test.cmd" || exit /b 1
set "STACK=" & call "!SCRIPT_DIR!\test_reactos_idempotency.cmd" || exit /b 1
echo [OK]       All ReactOS distribution tests PASSED.
exit /b 0
