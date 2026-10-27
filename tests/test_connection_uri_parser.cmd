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

:: # test_connection_uri_parser.cmd
::
:: ## Overview
:: Windows verification test suite for universal database connection URI parser.
::
:: ## Usage
::   call tests\test_connection_uri_parser.cmd

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

echo ==> Testing Connection URI Parser on Windows...

echo [TEST 1] Testing MySQL URI parsing...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\parse_connection_uri.cmd" "mysql://usr_test:p%%40ss%%23word@db.example.org:3308/sample_db?ssl-ca=/etc/ssl/ca.pem&timeout=15" --eval > "%TEMP%\test_uri_1.cmd"
call "%TEMP%\test_uri_1.cmd"
if not "%DB_ENGINE%"=="mysql" ( echo Failed ENGINE & exit /b 1 )
if not "%DB_HOST%"=="db.example.org" ( echo Failed HOST & exit /b 1 )
if not "%DB_PORT%"=="3308" ( echo Failed PORT & exit /b 1 )
if not "%DB_NAME%"=="sample_db" ( echo Failed NAME & exit /b 1 )
if not "%DB_USER%"=="usr_test" ( echo Failed USER & exit /b 1 )
if not "%DB_PASSWORD%"=="p@ss#word" ( echo Failed PASSWORD & exit /b 1 )
if not "%DB_USE_SSL%"=="1" ( echo Failed SSL & exit /b 1 )

echo [TEST 2] Testing PostgreSQL URI parsing...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\parse_connection_uri.cmd" "postgres://pg_admin:secure%%20token@127.0.0.1:5432/enterprise_db" --eval > "%TEMP%\test_uri_2.cmd"
call "%TEMP%\test_uri_2.cmd"
if not "%DB_ENGINE%"=="postgres" ( echo Failed ENGINE & exit /b 1 )
if not "%DB_PASSWORD%"=="secure token" ( echo Failed PASSWORD & exit /b 1 )

echo [TEST 3] Testing SQLite URI parsing...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\parse_connection_uri.cmd" "sqlite:///C:/var/lib/app/data.db" --eval > "%TEMP%\test_uri_3.cmd"
call "%TEMP%\test_uri_3.cmd"
if not "%DB_ENGINE%"=="sqlite" ( echo Failed ENGINE & exit /b 1 )
if not "%DB_NAME%"=="C:/var/lib/app/data.db" ( echo Failed PATH & exit /b 1 )

echo [TEST 4] Testing MongoDB URI parsing...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\parse_connection_uri.cmd" "mongodb://mongo_admin:p%%25ass%%26w%%3Dord@10.0.0.5:27017/admin?authSource=admin&replicaSet=rs0" --eval > "%TEMP%\test_uri_4.cmd"
call "%TEMP%\test_uri_4.cmd"
if not "%DB_ENGINE%"=="mongodb" ( echo Failed ENGINE & exit /b 1 )
if not "%DB_PASSWORD%"=="p%%ass&w=ord" ( echo Failed PASSWORD & exit /b 1 )

echo [TEST 5] Testing Redis URI parsing...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\parse_connection_uri.cmd" "redis://:super_s3cr3t@cache.local:6379/1" --eval > "%TEMP%\test_uri_5.cmd"
call "%TEMP%\test_uri_5.cmd"
if not "%DB_ENGINE%"=="redis" ( echo Failed ENGINE & exit /b 1 )
if not "%DB_PASSWORD%"=="super_s3cr3t" ( echo Failed PASSWORD & exit /b 1 )

echo [SUCCESS] Connection URI Parser verification succeeded on Windows!
exit /b 0
