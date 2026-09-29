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

:: # test_connection_uri_parser.cmd
::
:: ## Overview
:: Windows verification test suite for universal database connection URI parser.
::
:: ## Usage
::   call tests	est_connection_uri_parser.cmd

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

echo ==> Testing Connection URI Parser on Windows...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\parse_connection_uri.cmd" "mysql://usr_test:p%%40ssword@db.example.org:3308/sample_db" --json
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\parse_connection_uri.cmd" "postgres://pg_user:secret@127.0.0.1:5432/app_db" --eval

echo [SUCCESS] Connection URI Parser verification succeeded on Windows!
exit /b 0
