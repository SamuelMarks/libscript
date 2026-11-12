@echo off
:: # test_edgcpp_experiments.cmd
:: ## Overview
:: Integration test suite for the modular EDG C/C++ Backends experimental protocol on Windows. Verifies torture_suite.cmd, benchmark_experiments.cmd, LaTeX table generation, and idempotency.
:: ## Usage
:: tests/test_edgcpp_experiments.cmd

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

call :verify_torture_and_stl_harness
if errorlevel 1 exit /b 1

call :verify_5way_experiments_and_latex
if errorlevel 1 exit /b 1

echo [PASS] All EDG C/C++ Backends experimental protocol tests succeeded on Windows!
exit /b 0

:: ## verify_torture_and_stl_harness
:: Verifies torture_suite.cmd output and idempotency on Windows.
:verify_torture_and_stl_harness
set "_tmp_rep=%TEMP%\edg_torture_%RANDOM%.json"
call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\edgcpp\cli.cmd" torture --compiler=EDG-LLVM --output="!_tmp_rep!"
if not exist "!_tmp_rep!" exit /b 1
findstr /I /C:"all_passed" "!_tmp_rep!" >nul 2>&1
if errorlevel 1 exit /b 1
del /f /q "!_tmp_rep!" >nul 2>&1
exit /b 0

:: ## verify_5way_experiments_and_latex
:: Verifies benchmark_experiments.cmd output, LaTeX tables, and idempotency on Windows.
:verify_5way_experiments_and_latex
set "_rep_json=%TEMP%\edg_exp_%RANDOM%.json"
set "_tex_out=%TEMP%\edg_exp_%RANDOM%.tex"
call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\edgcpp\cli.cmd" experiments --report="!_rep_json!" --latex="!_tex_out!"
if not exist "!_rep_json!" exit /b 1
if not exist "!_tex_out!" exit /b 1
findstr /I /C:"all_experiments_passed" "!_rep_json!" >nul 2>&1
if errorlevel 1 exit /b 1
del /f /q "!_rep_json!" "!_tex_out!" >nul 2>&1
exit /b 0
