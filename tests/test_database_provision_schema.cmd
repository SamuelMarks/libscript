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

set "TEST_DB=%TEMP%\test_schema_%RANDOM%.db"

:: Setup Mock Environment
set "MOCK_DIR=%TEMP%\db_prov_mock_%RANDOM%"
if not exist "%MOCK_DIR%" mkdir "%MOCK_DIR%"
set "PATH=%MOCK_DIR%;%PATH%"

set "MOCK_MYSQL_LOG=%MOCK_DIR%\mysql_log.txt"
echo @echo off > "%MOCK_DIR%\mysql.cmd"
echo echo MYSQL CALLED WITH: %%* ^>^> "%%MOCK_MYSQL_LOG%%" >> "%MOCK_DIR%\mysql.cmd"

set "MOCK_PSQL_LOG=%MOCK_DIR%\psql_log.txt"
echo @echo off > "%MOCK_DIR%\psql.cmd"
echo echo PSQL CALLED WITH: %%* ^>^> "%%MOCK_PSQL_LOG%%" >> "%MOCK_DIR%\psql.cmd"
echo echo %%* ^| findstr /C:"SELECT 1 FROM pg_database" ^>nul >> "%MOCK_DIR%\psql.cmd"
echo if not errorlevel 1 ( if "%%PSQL_MOCK_DB_EXISTS%%"=="1" ( echo 1 ) else ( echo. ) ) >> "%MOCK_DIR%\psql.cmd"
echo echo %%* ^| findstr /C:"SELECT 1 FROM pg_roles" ^>nul >> "%MOCK_DIR%\psql.cmd"
echo if not errorlevel 1 ( if "%%PSQL_MOCK_ROLE_EXISTS%%"=="1" ( echo 1 ) else ( echo. ) ) >> "%MOCK_DIR%\psql.cmd"

set "MOCK_MONGOSH_LOG=%MOCK_DIR%\mongosh_log.txt"
echo @echo off > "%MOCK_DIR%\mongosh.cmd"
echo echo MONGOSH CALLED WITH: %%* ^>^> "%%MOCK_MONGOSH_LOG%%" >> "%MOCK_DIR%\mongosh.cmd"

echo [TEST 1] Testing SQLite Provisioning on Windows (Pass 1)...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\provision_schema.cmd" --engine sqlite --schema "%TEST_DB%" --user u --password p

echo [TEST 1] Testing SQLite Provisioning on Windows (Pass 2)...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\provision_schema.cmd" --engine sqlite --schema "%TEST_DB%" --user u --password p

echo [TEST 2] Testing MySQL Provisioning on Windows...
if exist "%MOCK_MYSQL_LOG%" del "%MOCK_MYSQL_LOG%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\provision_schema.cmd" --engine mysql --schema "testdb" --user "testuser" --password "testpass"
findstr /C:"CREATE DATABASE IF NOT EXISTS \`testdb\`" "%MOCK_MYSQL_LOG%" >nul || ( echo Failed mysql db & exit /b 1 )
findstr /C:"CREATE USER IF NOT EXISTS 'testuser'@'localhost'" "%MOCK_MYSQL_LOG%" >nul || ( echo Failed mysql user & exit /b 1 )

echo [TEST 3] Testing Postgres Provisioning (Pass 1 - Create)...
if exist "%MOCK_PSQL_LOG%" del "%MOCK_PSQL_LOG%"
set "PSQL_MOCK_DB_EXISTS=0"
set "PSQL_MOCK_ROLE_EXISTS=0"
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\provision_schema.cmd" --engine postgres --schema "testdb" --user "testuser" --password "testpass"
findstr /C:"CREATE DATABASE \"testdb\"" "%MOCK_PSQL_LOG%" >nul || ( echo Failed postgres db & exit /b 1 )
findstr /C:"CREATE USER \"testuser\"" "%MOCK_PSQL_LOG%" >nul || ( echo Failed postgres user & exit /b 1 )

echo [TEST 3] Testing Postgres Provisioning (Pass 2 - Exists)...
if exist "%MOCK_PSQL_LOG%" del "%MOCK_PSQL_LOG%"
set "PSQL_MOCK_DB_EXISTS=1"
set "PSQL_MOCK_ROLE_EXISTS=1"
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\provision_schema.cmd" --engine postgres --schema "testdb" --user "testuser" --password "testpass"
findstr /C:"CREATE DATABASE" "%MOCK_PSQL_LOG%" >nul && ( echo Failed idempotency & exit /b 1 )
findstr /C:"CREATE USER" "%MOCK_PSQL_LOG%" >nul && ( echo Failed idempotency & exit /b 1 )

echo [TEST 4] Testing MongoDB Provisioning on Windows...
if exist "%MOCK_MONGOSH_LOG%" del "%MOCK_MONGOSH_LOG%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\provision_schema.cmd" --engine mongodb --schema "testdb" --user "testuser" --password "testpass"
findstr /C:"createUser" "%MOCK_MONGOSH_LOG%" >nul || ( echo Failed mongodb & exit /b 1 )

rmdir /S /Q "%MOCK_DIR%"
if exist "%TEST_DB%" del "%TEST_DB%"

echo [SUCCESS] Schema Provisioning verification succeeded on Windows!
exit /b 0
