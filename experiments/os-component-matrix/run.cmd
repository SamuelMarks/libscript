@echo off
:: # run.cmd
:: ## Overview
:: Aggregates multi-OS test markers on Windows into `matrix_results.json` and updates `README.md`.
:: ## Usage
:: run.cmd [--results-dir=<dir>] [--readme-out=<README.md>]

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "RESULTS_DIR=!LIBSCRIPT_ROOT_DIR!\build\experiments\os-component-matrix"
set "TARGET_README=!LIBSCRIPT_ROOT_DIR!\README.md"
if not exist "!RESULTS_DIR!" mkdir "!RESULTS_DIR!"
call "!LIBSCRIPT_ROOT_DIR!\tests\update_results.cmd" --output "!TARGET_README!" --json "!RESULTS_DIR!\matrix_results.json"
exit /b !errorlevel!
