@echo off
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

:: # test_database_provision_schema.cmd
::
:: ## Overview
:: Windows verification test suite for universal schema provisioning.
::
:: ## Usage
::   call tests	est_database_provision_schema.cmd

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:found_root

set "TEST_DB=%TEMP%	est_schema_%RANDOM%.db"

echo ==> Testing SQLite Provisioning on Windows (Pass 1)...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\provision_schema.cmd" --engine sqlite --schema "%TEST_DB%"

echo ==> Testing SQLite Provisioning on Windows (Pass 2)...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\provision_schema.cmd" --engine sqlite --schema "%TEST_DB%"

echo ==> Testing SQLite Deprovisioning on Windows...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\deprovision_schema.cmd" --engine sqlite --schema "%TEST_DB%"

if exist "%TEST_DB%" (
    echo [ERROR] Test DB still exists after deprovisioning >&2
    exit /b 1
)

echo [SUCCESS] Schema Provisioning verification succeeded on Windows!
exit /b 0
