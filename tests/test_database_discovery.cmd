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

:: # test_database_discovery.cmd
::
:: ## Overview
:: Windows verification test suite for universal database discovery engine.
::
:: ## Usage
::   call tests	est_database_discovery.cmd

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

echo ==> Testing Universal Database Discovery Engine on Windows...

:: Setup Mock Environment
set "MOCK_DIR=%TEMP%\db_mock_%RANDOM%"
if not exist "%MOCK_DIR%" mkdir "%MOCK_DIR%"
set "PATH=%MOCK_DIR%;%PATH%"

echo @echo off > "%MOCK_DIR%\netstat.cmd"
echo if exist "%%MOCK_NETSTAT_OUTPUT%%" type "%%MOCK_NETSTAT_OUTPUT%%" >> "%MOCK_DIR%\netstat.cmd"

echo @echo off > "%MOCK_DIR%\sc.cmd"
echo exit /b 1 >> "%MOCK_DIR%\sc.cmd"

set "MOCK_NETSTAT_OUTPUT=%MOCK_DIR%\netstat_out.txt"

echo [TEST 0] Testing discovery --check across all engines via mock tcp...

echo   TCP    0.0.0.0:3306           0.0.0.0:0              LISTENING > "%MOCK_NETSTAT_OUTPUT%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\discover_databases.cmd" --check --engine mysql
if errorlevel 1 ( echo Failed mysql & exit /b 1 )

echo   TCP    0.0.0.0:5432           0.0.0.0:0              LISTENING > "%MOCK_NETSTAT_OUTPUT%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\discover_databases.cmd" --check --engine postgres
if errorlevel 1 ( echo Failed postgres & exit /b 1 )

echo   TCP    0.0.0.0:27017          0.0.0.0:0              LISTENING > "%MOCK_NETSTAT_OUTPUT%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\discover_databases.cmd" --check --engine mongodb
if errorlevel 1 ( echo Failed mongodb & exit /b 1 )

echo   TCP    0.0.0.0:6379           0.0.0.0:0              LISTENING > "%MOCK_NETSTAT_OUTPUT%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\discover_databases.cmd" --check --engine redis
if errorlevel 1 ( echo Failed redis & exit /b 1 )

echo [TEST 1] Testing --json output...
(
echo   TCP    0.0.0.0:3306           0.0.0.0:0              LISTENING
echo   TCP    0.0.0.0:5432           0.0.0.0:0              LISTENING
echo   TCP    0.0.0.0:27017          0.0.0.0:0              LISTENING
echo   TCP    0.0.0.0:6379           0.0.0.0:0              LISTENING
) > "%MOCK_NETSTAT_OUTPUT%"

call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\discover_databases.cmd" --json > "%MOCK_DIR%\json_out.txt"
findstr /C:"mysql" "%MOCK_DIR%\json_out.txt" >nul || ( echo Failed json mysql & exit /b 1 )
findstr /C:"postgres" "%MOCK_DIR%\json_out.txt" >nul || ( echo Failed json postgres & exit /b 1 )
findstr /C:"mongodb" "%MOCK_DIR%\json_out.txt" >nul || ( echo Failed json mongodb & exit /b 1 )
findstr /C:"redis" "%MOCK_DIR%\json_out.txt" >nul || ( echo Failed json redis & exit /b 1 )

echo [TEST 2] Testing discovery idempotency (two passes)...
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\discover_databases.cmd" --eval >nul 2>&1
call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\discover_databases.cmd" --eval >nul 2>&1

rmdir /S /Q "%MOCK_DIR%"

echo [SUCCESS] Database discovery verification succeeded on Windows!
exit /b 0
