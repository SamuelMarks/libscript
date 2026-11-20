@echo off
:: # test_rest_api.cmd
::
:: ## Overview
:: Hermetic Windows CMake build and CLI verification suite for the native C11 libscript-rest-api server.
::
:: ## Usage
:: tests\test_rest_api.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

where cmake >nul 2>&1
if errorlevel 1 (
    echo [SKIP] cmake not installed; skipping C11 REST API build test.
    exit /b 0
)

set "TEST_TMP=!LIBSCRIPT_ROOT_DIR!\tests_tmp\rest_api_win_%RANDOM%"
if not exist "!TEST_TMP!" mkdir "!TEST_TMP!"
cmake -S "!LIBSCRIPT_ROOT_DIR!\libscript-rest-api" -B "!TEST_TMP!\build" >nul
if errorlevel 1 (
    rmdir /s /q "!TEST_TMP!" 2>nul
    exit /b 1
)
cmake --build "!TEST_TMP!\build" >nul
if errorlevel 1 (
    rmdir /s /q "!TEST_TMP!" 2>nul
    exit /b 1
)
ctest --test-dir "!TEST_TMP!\build" --output-on-failure
set "_RC=!ERRORLEVEL!"
rmdir /s /q "!TEST_TMP!" 2>nul
if "!_RC!" neq "0" exit /b !_RC!
echo [PASS] Windows C11 libscript-rest-api build and CTest verification succeeded.
exit /b 0
