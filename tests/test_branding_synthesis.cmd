@echo off
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

:: # test_branding_synthesis.cmd
::
:: ## Overview
:: Windows verification test suite for universal branding synthesis.
::
:: ## Usage
::   call tests\test_branding_synthesis.cmd

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

set "TEST_OUT=%TEMP%\branding_test_%RANDOM%"
if not exist "%TEST_OUT%" mkdir "%TEST_OUT%"

echo ==> Testing Universal Branding Synthesis on Windows...
call "%LIBSCRIPT_ROOT_DIR%\packaging\synthesize_branding.cmd" "%LIBSCRIPT_ROOT_DIR%\_lib\web-apps\wordpress" --output-dir "%TEST_OUT%"

if not exist "%TEST_OUT%\banner_side.bmp" (
    echo [ERROR] banner_side.bmp was not generated >&2
    exit /b 1
)

rd /s /q "%TEST_OUT%"
echo [SUCCESS] Branding synthesis verification succeeded on Windows!
exit /b 0
