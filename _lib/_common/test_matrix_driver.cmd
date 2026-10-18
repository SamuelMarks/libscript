@echo off
:: # test_matrix_driver.cmd
::
:: ## Overview
:: Unified 6-OS test matrix driver and per-component 4-stage lifecycle contract probe for Windows.
:: Provides shared subroutines for VM snapshot restoration (`vanilla`), manifest OS/architecture
:: filtering, 4-stage component verification (`install` -> `test` -> `which/env/ls` ->
:: `2x idempotent install+test` -> `uninstall`), and live `tests\update_results.cmd` updates.
::
:: ## Usage
:: call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\test_matrix_driver.cmd" [subroutine] [args...]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

if "%~1"=="" exit /b 0
if /i "%~1"=="probe" (
    call :run_4stage_probe "%~2"
    exit /b !errorlevel!
)
exit /b 0

:: ## run_4stage_probe
:: Executes the 4-stage version manager lifecycle contract check for a target component on Windows.
:run_4stage_probe
set "PROBE_TARGET=%~1"
if "%PROBE_TARGET%"=="" exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install "%PROBE_TARGET%"
if errorlevel 1 exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" test "%PROBE_TARGET%"
if errorlevel 1 exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" which "%PROBE_TARGET%" latest >nul 2>&1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" env "%PROBE_TARGET%" latest >nul 2>&1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" ls "%PROBE_TARGET%" >nul 2>&1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install "%PROBE_TARGET%"
if errorlevel 1 exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" test "%PROBE_TARGET%"
if errorlevel 1 exit /b 1
exit /b 0
