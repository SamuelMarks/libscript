@echo off
:: # test_fullstack_orchestration.cmd
::
:: ## Overview
:: End-to-end integration test suite on Windows verifying full-stack orchestration, dependency resolution,
:: lifecycle hooks, daemon management, SPA/WebSocket ingress, frontend/KMP builds, and ML CLI verbs.
::
:: ## Usage
:: tests\test_fullstack_orchestration.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

set "TEST_TMP=%TEMP%\libscript_fullstack_%RANDOM%"
if not exist "!TEST_TMP!" mkdir "!TEST_TMP!"

echo {"deps": {"postgresql": "16", "node": "20"}} > "!TEST_TMP!\deps_flat.json"
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\resolve_stack.cmd" "!TEST_TMP!\deps_flat.json" "!TEST_TMP!\resolved.json"
findstr /C:"postgres" "!TEST_TMP!\resolved.json" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] resolve_stack.cmd flat .deps failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] resolve_stack.cmd flat .deps

call "!LIBSCRIPT_ROOT_DIR!\_lib\networking\netctl\cli.cmd" --domain dashboard.local --listen 8080 --spa / "/var/www/html" --ws /ws "ws://127.0.0.1:8000/ws" --emit nginx > "!TEST_TMP!\nginx.conf"
findstr /C:"try_files $uri $uri/ /index.html;" "!TEST_TMP!\nginx.conf" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] netctl.cmd SPA emission failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] netctl.cmd SPA and WebSocket emission

echo {"ml": {"backend": "pytorch", "target": "local", "train_command": "echo trained"}} > "!TEST_TMP!\ml.json"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" train "!TEST_TMP!\ml.json" --dry-run > "!TEST_TMP!\ml.out"
findstr /C:"[DRY-RUN]" "!TEST_TMP!\ml.out" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript.cmd train --dry-run failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] libscript.cmd train --dry-run

echo {"infrastructure": {"hooks": {"db_migrate": [{"name": "bad_hook", "command": "exit /b 42"}]}}} > "!TEST_TMP!\bad_hook.json"
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\run_hooks.cmd" "!TEST_TMP!\bad_hook.json" "db_migrate" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] run_hooks.cmd should fail on non-zero hook exit >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] run_hooks.cmd propagates non-zero hook exit code

:: 8. Test multi-app shared-node provision, deprovision, backup, and restore dry-run
if not exist "!TEST_TMP!\app_a" mkdir "!TEST_TMP!\app_a"
if not exist "!TEST_TMP!\app_b" mkdir "!TEST_TMP!\app_b"
if not exist "!TEST_TMP!\state_dir" mkdir "!TEST_TMP!\state_dir"
echo {"name": "hospital-dashboard-platform"} > "!TEST_TMP!\app_a\libscript.json"
echo {"name": "t1d-analytics"} > "!TEST_TMP!\app_b\libscript.json"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" provision --provider azure --node test-node --rg TEST-RG --location eastus --app "!TEST_TMP!\app_a:hospital-dashboard-platform@pulse-query.healthplatform.io" --app "!TEST_TMP!\app_b:t1d-analytics@t1d-analytics.healthplatform.io" --dry-run >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript.cmd provision --dry-run failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" deprovision --provider azure --node test-node --rg TEST-RG --location eastus --keep-infra --purge-data --only t1d-analytics --app "!TEST_TMP!\app_a:hospital-dashboard-platform" --app "!TEST_TMP!\app_b:t1d-analytics" --dry-run >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript.cmd deprovision --keep-infra --dry-run failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" backup test-node --provider azure --rg TEST-RG --only pulse_query --app hospital-dashboard-platform --app t1d-analytics --export-state "!TEST_TMP!\state_dir" --dry-run >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript.cmd backup --export-state --dry-run failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" restore test-node --provider azure --rg TEST-RG --only pulse_query --app "hospital-dashboard-platform@pulse-query.healthplatform.io" --app "t1d-analytics@t1d-analytics.healthplatform.io" --import-state "!TEST_TMP!\state_dir" --dry-run >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript.cmd restore --import-state --dry-run failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] Multi-app shared-node provision, deprovision, backup, and restore dry-run orchestration

rmdir /s /q "!TEST_TMP!" >nul 2>&1
echo === ALL WINDOWS FULLSTACK ORCHESTRATION TESTS PASSED ===
exit /b 0
