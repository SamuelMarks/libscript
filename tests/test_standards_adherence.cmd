@echo off
:: # test_standards_adherence.cmd
:: ## Overview
:: Regression test suite on Windows verifying Tier 3.5/4 Batch engine parity,
:: 2x idempotency, zero-PowerShell gawk/jq/certutil helpers, and experiment scaffolding.
:: ## Usage
:: test_standards_adherence.cmd

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

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

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

set "_DP=%~dp0"
set "_BS=!_DP:~-1!"
set "TEST_TMP=%TEMP%!_BS!ls_std_test_%RANDOM%_%RANDOM%"
if not exist "!TEST_TMP!" mkdir "!TEST_TMP!"

echo === 1. Test uuid_gen.cmd Determinism ===
set "_U1="
set "_U2="
for /f "usebackq delims=" %%U in (`call "!LIBSCRIPT_ROOT_DIR!!_BS!_lib!_BS!_common!_BS!uuid_gen.cmd" "demo-seed"`) do set "_U1=%%U"
for /f "usebackq delims=" %%U in (`call "!LIBSCRIPT_ROOT_DIR!!_BS!_lib!_BS!_common!_BS!uuid_gen.cmd" "demo-seed"`) do set "_U2=%%U"
if "!_U1!"=="" ( echo [FAIL] uuid_gen.cmd returned empty output 1>&2 & goto :cleanup_fail )
if not "!_U1!"=="!_U2!" ( echo [FAIL] uuid_gen.cmd non-deterministic: !_U1! vs !_U2! 1>&2 & goto :cleanup_fail )

echo === 2. Test Topology Engine 2x Idempotency, Scale, Drain, Failover, Upgrade, Destroy ===
> "!TEST_TMP!!_BS!topo.json" echo {"name":"win-std-cluster","substrate":{"provider":"local"},"node_groups":[{"name":"db","count":2,"roles":["leader","follower"]}]}
set "LIBSCRIPT_TOPOLOGY_STATE_DIR=!TEST_TMP!!_BS!state"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!topologies!_BS!engine.cmd" up "!TEST_TMP!!_BS!topo.json" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!topologies!_BS!engine.cmd" up "!TEST_TMP!!_BS!topo.json" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!topologies!_BS!engine.cmd" scale "!TEST_TMP!!_BS!topo.json" db=3 >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!topologies!_BS!engine.cmd" drain "!TEST_TMP!!_BS!topo.json" db-2 >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!topologies!_BS!engine.cmd" failover "!TEST_TMP!!_BS!topo.json" db-0 >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!topologies!_BS!engine.cmd" upgrade "!TEST_TMP!!_BS!topo.json" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!topologies!_BS!engine.cmd" destroy "!TEST_TMP!!_BS!topo.json" >nul
if errorlevel 1 goto :cleanup_fail

echo === 3. Test Payload Schedulers (native, nomad, slurm_ray) ===
> "!TEST_TMP!!_BS!payload.json" echo {"name":"demo-worker","type":"service","artifact":{"format":"oci-image","image":"alpine:3.20","entrypoint":["cmd.exe","/c","echo"]},"resources":{"cpu_cores":2,"memory_mb":512,"gpu_count":1},"scaling":{"replicas":2}}
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!payloads!_BS!schedulers!_BS!native.cmd" compile "!TEST_TMP!!_BS!payload.json" --init sc >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!payloads!_BS!schedulers!_BS!nomad.cmd" compile "!TEST_TMP!!_BS!payload.json" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!payloads!_BS!schedulers!_BS!slurm_ray.cmd" compile "!TEST_TMP!!_BS!payload.json" >nul
if errorlevel 1 goto :cleanup_fail

echo === 4. Test Experiment Scaffold 2x Idempotency ===
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!cli!_BS!commands!_BS!experiment!_BS!scaffold.cmd" demo-win-suite "--out-root=!TEST_TMP!!_BS!exps" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!cli!_BS!commands!_BS!experiment!_BS!scaffold.cmd" demo-win-suite "--out-root=!TEST_TMP!!_BS!exps" >nul
if errorlevel 1 goto :cleanup_fail

if exist "!TEST_TMP!" rmdir /s /q "!TEST_TMP!" >nul 2>&1
echo [PASS] All Windows standards adherence regression tests succeeded.
exit /b 0

:: ## cleanup_fail
:: Cleans temporary test directory and exits with failure status 1.
:cleanup_fail
if exist "!TEST_TMP!" rmdir /s /q "!TEST_TMP!" >nul 2>&1
echo [FAIL] Windows standards adherence regression test failed. 1>&2
exit /b 1
