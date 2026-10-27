@echo off
:: # test_sqlite_compiler_matrix.cmd
::
:: ## Overview
:: Integration test suite for the 4-way SQLite amalgamation compiler matrix on Windows.
::
:: ## Usage
:: tests\test_sqlite_compiler_matrix.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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

call :run_sqlite_matrix_windows
if errorlevel 1 exit /b 1
echo [PASS] SQLite compiler matrix test succeeded on Windows.
exit /b 0

:: ## run_sqlite_matrix_windows
:: Executes compare_compilers.cmd and checks that the JSON report exists.
:run_sqlite_matrix_windows
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\sqlite\compare_compilers.cmd"
if not exist "%LIBSCRIPT_ROOT_DIR%\build\sqlite-compiler-comparison.json" exit /b 1
exit /b 0
