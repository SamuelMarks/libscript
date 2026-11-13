@echo off
:: # test_libtpu_experiments.cmd
:: ## Overview
:: Windows integration and 2x idempotency test suite for `_lib\toolchains\libtpu-rs\benchmark_experiments.cmd` across Suites `E0`–`E8`.
:: ## Usage
:: tests\test_libtpu_experiments.cmd

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
if "!d!"=="" exit /b 1
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "_RES=%TEMP%\libtpu_exp_win_%RANDOM%"
set "LIBTPU_RS_ALLOW_DIRTY=1"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" libtpu-rs experiments --synthetic-fixtures --subsuites=E0,E1,E2,E3,E4,E5,E6,E7,E8 "--results-dir=!_RES!"
if errorlevel 1 exit /b 1
if not exist "!_RES!\generated_metrics.tex" exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" libtpu-rs experiments --synthetic-fixtures --subsuites=E0,E8 "--results-dir=!_RES!"
if errorlevel 1 exit /b 1
rmdir /s /q "!_RES!" >nul 2>&1
echo [PASS] Windows libtpu-rs E0-E8 integration and 2x idempotency tests succeeded!
exit /b 0
