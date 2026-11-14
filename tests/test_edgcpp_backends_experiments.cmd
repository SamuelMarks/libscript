@echo off
:: # test_edgcpp_backends_experiments.cmd
:: ## Overview
:: Comprehensive Windows test suite for `edgcpp-backends-suite` (E0-E7), 2x idempotency, and negative integrity gates.
:: ## Usage
:: tests\test_edgcpp_backends_experiments.cmd

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
if "!d!"=="" exit /b 1
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "_WDIR=%TEMP%\test_edgcpp_backends_%RANDOM%"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" edgcpp-backends-suite experiments --synthetic-fixtures "--results-dir=!_WDIR!" || exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" edgcpp-backends-suite experiments --synthetic-fixtures "--results-dir=!_WDIR!" || exit /b 1
if not exist "!_WDIR!\generated_metrics.tex" exit /b 1

set "EDGCPP_BACKENDS_SUITE_SYNTHETIC=0"
call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\edgcpp-backends-suite\suites\e6_corpus_and_kernel.cmd" "C:\none" "!_WDIR!\bad_k" "windows_x64" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] E6 allowed fake Linux kernel Kbuild on Windows! 1>&2
    exit /b 1
)
rmdir /s /q "!_WDIR!" 2>nul
echo [PASS] All edgcpp_backends Windows E0-E7 and negative-gate tests succeeded!
exit /b 0
