@echo off
:: # make.bat
::
:: ## Overview
:: Make replacement for windows
::
:: ## Usage
:: make.bat [args]
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
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

:: ## Overview
:: Entry point for common make tasks in Windows batch environment.
::
:: ## Usage
:: make.bat <target>
:: Targets: local_tests_toolchain, local_tests_languages, local_tests_databases


if "%~1"=="test" goto local_tests_all
if "%~1"=="local_tests_all" goto local_tests_all
if "%~1"=="test_component" goto test_component
if "%~1"=="local_tests_toolchain" goto local_tests_toolchain
if "%~1"=="local_tests_languages" goto local_tests_languages
if "%~1"=="local_tests_databases" goto local_tests_databases

echo Unknown target %1
exit /b 1

:: ## local_tests_all
:: Performs the local_tests_all operation and updates component state.
:local_tests_all
call tests\run_local_tests.cmd all
exit /b

:: ## test_component
:: Performs the test_component operation and updates component state.
:test_component
if "%~2"=="" (
    echo Usage: make.bat test_component ^<component_name^>
    exit /b 1
)
call tests\run_local_tests.cmd %2
exit /b

:: ## local_tests_toolchain
:: Performs the local_tests_toolchain operation and updates component state.
:local_tests_toolchain
call tests\run_local_tests.cmd toolchains
exit /b

:: ## local_tests_languages
:: Performs the local_tests_languages operation and updates component state.
:local_tests_languages
call tests\run_local_tests.cmd languages
exit /b

:: ## local_tests_databases
:: Performs the local_tests_databases operation and updates component state.
:local_tests_databases
call tests\run_local_tests.cmd databases
exit /b
