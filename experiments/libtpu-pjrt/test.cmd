@echo off
:: # test.cmd
:: ## Overview
:: Smoke and idempotent Suite E9 + E8 synthesis validation test for the `libtpu-pjrt` experiment plugin on Windows.
:: ## Usage
:: test.cmd

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
:: Validates manifest and verifies synthetic E0 + E9 + E8 execution idempotently.
:root_found
call "!LIBSCRIPT_ROOT_DIR!\experiments\engine.cmd" validate "libtpu-pjrt" >nul
if errorlevel 1 exit /b !errorlevel!
set "_TMP=%TEMP%\libtpu_pjrt_smoke_!RANDOM!"
if not exist "!_TMP!" mkdir "!_TMP!"
set "STACK="
call "!SCRIPT_DIR!\provision.cmd" --dry-run >nul
if errorlevel 1 exit /b 1
set "STACK="
call "!SCRIPT_DIR!\benchmark_experiments.cmd" --synthetic-fixtures --subsuites=E0,E9,E8 "--results-dir=!_TMP!\res" >nul
if errorlevel 1 exit /b 1
set "STACK="
call "!SCRIPT_DIR!\benchmark_experiments.cmd" --synthetic-fixtures --subsuites=E0,E9,E8 "--results-dir=!_TMP!\res" >nul
if errorlevel 1 exit /b 1
if not exist "!_TMP!\res\e9_framework_comparison.json" exit /b 1
if not exist "!_TMP!\res\generated_metrics.tex" exit /b 1
rmdir /s /q "!_TMP!" >nul 2>&1
exit /b 0
