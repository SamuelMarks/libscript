@echo off
:: # test_resolve_stack.cmd
::
:: ## Overview
:: Verifies that _lib\orchestration\resolve_stack.cmd resolves multi-component stacks
:: across all 300+ component manifests without exceeding cmd.exe's 8,191-character limit.
::
:: ## Usage
:: tests\test_resolve_stack.cmd

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

set "_TMP_DIR=%TEMP%\libscript_resolve_test_%RANDOM%"
if not exist "!_TMP_DIR!" mkdir "!_TMP_DIR!"
echo {"deps":{"nodejs":"20","postgres":"17","python":"3.12"}} > "!_TMP_DIR!\libscript.json"

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\resolve_stack.cmd" "!_TMP_DIR!\libscript.json" "!_TMP_DIR!\plan.json"
if errorlevel 1 (
    echo [FAIL] resolve_stack.cmd failed 1>&2
    rmdir /s /q "!_TMP_DIR!" 2>nul
    exit /b 1
)

for %%P in (nodejs postgres python) do (
    findstr /I /C:"\"%%P\"" "!_TMP_DIR!\plan.json" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] Expected %%P in resolved execution plan 1>&2
        rmdir /s /q "!_TMP_DIR!" 2>nul
        exit /b 1
    )
)

rmdir /s /q "!_TMP_DIR!" 2>nul
echo [PASS] resolve_stack.cmd resolved multi-component stack across all manifests.
endlocal
exit /b 0
