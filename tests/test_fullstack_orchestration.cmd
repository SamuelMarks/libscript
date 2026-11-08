@echo off
:: # test_fullstack_orchestration.cmd
:: ## Overview
:: End-to-end integration test suite on Windows verifying full-stack orchestration, dependency resolution, lifecycle hooks, daemon management, SPA/WebSocket ingress, frontend/KMP builds, and ML CLI verbs.
:: ## Usage
:: tests\test_fullstack_orchestration.cmd

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
echo {"name": "dashboard-platform"} > "!TEST_TMP!\app_a\libscript.json"
echo {"name": "analytics-service"} > "!TEST_TMP!\app_b\libscript.json"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" provision --provider azure --node test-node --rg TEST-RG --location eastus --app "!TEST_TMP!\app_a:dashboard-platform@metrics-query.example.org" --app "!TEST_TMP!\app_b:analytics-service@analytics-service.example.org" --dry-run >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript.cmd provision --dry-run failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" deprovision --provider azure --node test-node --rg TEST-RG --location eastus --keep-infra --purge-data --only analytics-service --app "!TEST_TMP!\app_a:dashboard-platform" --app "!TEST_TMP!\app_b:analytics-service" --dry-run >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript.cmd deprovision --keep-infra --dry-run failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" backup test-node --provider azure --rg TEST-RG --only metrics_query --app dashboard-platform --app analytics-service --export-state "!TEST_TMP!\state_dir" --dry-run >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript.cmd backup --export-state --dry-run failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" restore test-node --provider azure --rg TEST-RG --only metrics_query --app "dashboard-platform@metrics-query.example.org" --app "analytics-service@analytics-service.example.org" --import-state "!TEST_TMP!\state_dir" --dry-run >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript.cmd restore --import-state --dry-run failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] Multi-app shared-node provision, deprovision, backup, and restore dry-run orchestration

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\remote_sync.cmd" compute-hash "!TEST_TMP!\app_a" > "!TEST_TMP!\hash.out"
if errorlevel 1 (
    echo [FAIL] remote_sync.cmd compute-hash failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] remote_sync.cmd compute-hash

:: 9. Test remote_sync.cmd ssh-opts generates short ControlPath under 65 bytes even when TMPDIR is 90+ chars
set "STACK="
set "TMPDIR=/var/folders/w5/21g61wls7ksd3z8cxrj41s1c0000gn/T/very_long_nested_subdir_for_testing_90chars/"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\remote_sync.cmd" ssh-opts > "!TEST_TMP!\ssh_opts.out"
set "TMPDIR="
findstr /C:"ControlPath=/tmp/ls_mux/" "!TEST_TMP!\ssh_opts.out" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] remote_sync.cmd ssh-opts did not emit short ControlPath >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] remote_sync.cmd ssh-opts short ControlPath

:: 10. Test provision_frontend.cmd --compute-pkg-hash and --compute-src-hash modes
if not exist "!TEST_TMP!\fe_sub\src" mkdir "!TEST_TMP!\fe_sub\src"
echo {"name": "fe-sub", "version": "1.0.0"} > "!TEST_TMP!\fe_sub\package.json"
echo console.log("hi"); > "!TEST_TMP!\fe_sub\src\main.ts"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\provision_frontend.cmd" --compute-pkg-hash "!TEST_TMP!\fe_sub" > "!TEST_TMP!\pkg_hash1.out"
if errorlevel 1 (
    echo [FAIL] provision_frontend.cmd --compute-pkg-hash failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\provision_frontend.cmd" --compute-src-hash "!TEST_TMP!\fe_sub" > "!TEST_TMP!\src_hash1.out"
if errorlevel 1 (
    echo [FAIL] provision_frontend.cmd --compute-src-hash failed >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] provision_frontend.cmd --compute-pkg-hash and --compute-src-hash

:: 5. Test Ollama CPU runner defaults in env.cmd and >4 argument override-env persistence in service_install.cmd
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\ollama\env.cmd"
if not "!OLLAMA_FLASH_ATTENTION!"=="0" (
    echo [FAIL] ollama\env.cmd did not set OLLAMA_FLASH_ATTENTION=0 >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
if not "!OLLAMA_KV_CACHE_TYPE!"=="f16" (
    echo [FAIL] ollama\env.cmd did not set OLLAMA_KV_CACHE_TYPE=f16 >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
if not "!OLLAMA_CONTEXT_LENGTH!"=="2048" (
    echo [FAIL] ollama\env.cmd did not set OLLAMA_CONTEXT_LENGTH=2048 >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
set "LIBSCRIPT_DATA_DIR=!TEST_TMP!\win_svc_data"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\ollama\service.cmd" override-env "!TEST_TMP!\win_ol_models"
if not exist "!LIBSCRIPT_DATA_DIR!\ollama\.env.service" (
    echo [FAIL] ollama\service.cmd override-env did not create .env.service >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
findstr /C:"OLLAMA_CONTEXT_LENGTH=2048" "!LIBSCRIPT_DATA_DIR!\ollama\.env.service" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] service_install.cmd truncated OLLAMA_CONTEXT_LENGTH beyond 4 arguments >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
findstr /C:"OLLAMA_KEEP_ALIVE=10m" "!LIBSCRIPT_DATA_DIR!\ollama\.env.service" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] service_install.cmd truncated OLLAMA_KEEP_ALIVE beyond 4 arguments >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] ollama\env.cmd CPU defaults and service_install.cmd 11-key override-env persistence

:: 11. Test Let's Encrypt certificate store resolution and /.well-known/acme-challenge/ emission on Windows
if not exist "!TEST_TMP!\mnt_data\certs\live\pulse-query.healthplatform.io" mkdir "!TEST_TMP!\mnt_data\certs\live\pulse-query.healthplatform.io"
echo cert > "!TEST_TMP!\mnt_data\certs\live\pulse-query.healthplatform.io\fullchain.pem"
echo key > "!TEST_TMP!\mnt_data\certs\live\pulse-query.healthplatform.io\privkey.pem"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\networking\netctl\cli.cmd" --domain pulse-query.healthplatform.io --tls letsencrypt --cert-store-dir "!TEST_TMP!\mnt_data\certs" --listen 80 --listen 443 --spa / "/var/www/html" --emit nginx > "!TEST_TMP!\le_nginx.conf"
findstr /C:"location ^~ /.well-known/acme-challenge/" "!TEST_TMP!\le_nginx.conf" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] netctl.cmd did not emit /.well-known/acme-challenge/ >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
findstr /C:"ssl_certificate !TEST_TMP!\mnt_data\certs/live/pulse-query.healthplatform.io/fullchain.pem;" "!TEST_TMP!\le_nginx.conf" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] netctl.cmd did not resolve Let's Encrypt cert from CERT_STORE_DIR >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] Let's Encrypt persistent certificate store resolution and ACME challenge route on Windows

:: 12. Test DATA_DISK_MOUNT override for CERT_STORE_DIR in certbot\env.cmd
set "CERT_STORE_DIR="
set "DATA_DISK_MOUNT=!TEST_TMP!\custom_mount"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\security\certbot\env.cmd"
if not "!CERT_STORE_DIR!"=="!TEST_TMP!\custom_mount/certs" (
    echo [FAIL] certbot\env.cmd did not derive CERT_STORE_DIR from DATA_DISK_MOUNT ^(!CERT_STORE_DIR!^) >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] DATA_DISK_MOUNT overrides default /mnt/data in certbot\env.cmd

:: 13. Test .ingress.proxy_read_timeout propagation to NETCTL_PROXY_READ_TIMEOUT during libscript_Synchronize_Ingress
if not exist "!TEST_TMP!\ing_timeout" mkdir "!TEST_TMP!\ing_timeout"
(
echo {
echo   "ingress": {
echo     "provider": "nginx",
echo     "domain": "t1d-analytics.healthplatform.io",
echo     "proxy_read_timeout": 600,
echo     "routes": {
echo       "/api": "http://127.0.0.1:8000"
echo     }
echo   }
echo }
) > "!TEST_TMP!\ing_timeout\libscript.json"
set "NETCTL_PROXY_READ_TIMEOUT="
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\component_core.cmd" --synchronize-ingress "!TEST_TMP!\ing_timeout\libscript.json" --format nginx --out "!TEST_TMP!\ing_timeout\nginx.conf"
if not "!NETCTL_PROXY_READ_TIMEOUT!"=="600s" (
    echo [FAIL] libscript_Synchronize_Ingress did not set NETCTL_PROXY_READ_TIMEOUT=600s ^(!NETCTL_PROXY_READ_TIMEOUT!^) >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
findstr /C:"proxy_read_timeout 600s;" "!TEST_TMP!\ing_timeout\nginx.conf" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] libscript_Synchronize_Ingress did not emit proxy_read_timeout 600s in nginx.conf >&2
    rmdir /s /q "!TEST_TMP!" >nul 2>&1
    exit /b 1
)
echo [PASS] .ingress.proxy_read_timeout propagates to NETCTL_PROXY_READ_TIMEOUT during libscript_Synchronize_Ingress

rmdir /s /q "!TEST_TMP!" >nul 2>&1
echo === ALL WINDOWS FULLSTACK ORCHESTRATION TESTS PASSED ===
exit /b 0
