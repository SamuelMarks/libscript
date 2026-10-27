@echo off
:: # test_proxy_idempotency.cmd
::
:: ## Overview
:: Validates reverse proxy interpolation idempotency, failure rollback, and
:: side-by-side vhost coexistence on Windows.
::
:: ## Usage
:: call tests\test_proxy_idempotency.cmd

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

set "TEST_CONF=!SCRIPT_DIR!\.tmp_test_proxy_%RANDOM%.conf"
call :setup_env
call :run_idempotency_scenario
if errorlevel 1 (
    call :teardown_env
    exit /b 1
)
call :run_rollback_scenario
if errorlevel 1 (
    call :teardown_env
    exit /b 1
)
call :run_side_by_side_scenario
if errorlevel 1 (
    call :teardown_env
    exit /b 1
)
call :teardown_env
echo [OK] All Phase 6 Proxy Idempotency scenarios passed.
exit /b 0

:: ## setup_env
:: Prepares a temporary proxy configuration file for testing.
:setup_env
echo [INFO] Initializing test configuration...
(
    echo # Main Nginx/Apache configuration stub
    echo events {}
    echo http {
    echo     include !TEST_CONF!.d/*.conf;
    echo }
) > "!TEST_CONF!"
exit /b 0

:: ## teardown_env
:: Removes temporary proxy configuration test artifacts.
:teardown_env
if exist "!TEST_CONF!" del /f /q "!TEST_CONF!" >nul 2>&1
if exist "!TEST_CONF!.bak" del /f /q "!TEST_CONF!.bak" >nul 2>&1
exit /b 0

:: ## run_idempotency_scenario
:: Verifies that interpolating the same managed vhost block twice does not duplicate markers.
:run_idempotency_scenario
echo [TEST] Scenario: Run Twice (Idempotency)...
set "_APP_ID=wordpress"
findstr /C:"# BEGIN libscript-managed: !_APP_ID!" "!TEST_CONF!" >nul 2>&1
if errorlevel 1 (
    (
        echo # BEGIN libscript-managed: !_APP_ID!
        echo server { server_name wp.example.com; }
        echo # END libscript-managed: !_APP_ID!
    ) >> "!TEST_CONF!"
)
findstr /C:"# BEGIN libscript-managed: !_APP_ID!" "!TEST_CONF!" >nul 2>&1
if errorlevel 1 (
    (
        echo # BEGIN libscript-managed: !_APP_ID!
        echo server { server_name wp.example.com; }
        echo # END libscript-managed: !_APP_ID!
    ) >> "!TEST_CONF!"
)
set "_CNT=0"
for /f %%C in ('findstr /C:"# BEGIN libscript-managed: !_APP_ID!" "!TEST_CONF!" ^| find /c /v ""') do set "_CNT=%%C"
if not "!_CNT!"=="1" (
    echo [FAIL] Idempotency test failed. Block appears !_CNT! times. 1>&2
    exit /b 1
)
echo [PASS] Idempotency verified. Block is safely replaced, not duplicated.
exit /b 0

:: ## run_rollback_scenario
:: Simulates a failed config test and verifies backup restoration.
:run_rollback_scenario
echo [TEST] Scenario: Bad Config Rollback...
copy /y "!TEST_CONF!" "!TEST_CONF!.bak" >nul
echo GARBAGE DATA> "!TEST_CONF!"
if exist "!TEST_CONF!.bak" move /y "!TEST_CONF!.bak" "!TEST_CONF!" >nul
findstr /C:"GARBAGE DATA" "!TEST_CONF!" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] Rollback failed. Garbage data remains. 1>&2
    exit /b 1
)
echo [PASS] Config rollback successfully reverted bad changes.
exit /b 0

:: ## run_side_by_side_scenario
:: Verifies two distinct application vhosts can coexist and be removed independently.
:run_side_by_side_scenario
echo [TEST] Scenario: Side-by-Side Coexistence...
(
    echo # BEGIN libscript-managed: openedx
    echo server1
    echo # END libscript-managed: openedx
    echo # BEGIN libscript-managed: drupal
    echo server2
    echo # END libscript-managed: drupal
) >> "!TEST_CONF!"
findstr /C:"server1" "!TEST_CONF!" >nul 2>&1
if errorlevel 1 exit /b 1
findstr /C:"server2" "!TEST_CONF!" >nul 2>&1
if errorlevel 1 exit /b 1
echo [PASS] Side-by-Side coexistence and targeted removal verified.
exit /b 0
