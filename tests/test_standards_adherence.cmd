@echo off
:: # test_standards_adherence.cmd
:: ## Overview
:: Regression test suite on Windows verifying T0-T5 Batch engine parity,
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

set "_DP=%~dp0"
set "_BS=!_DP:~-1!"
set "TEST_TMP=%TEMP%!_BS!ls_std_test_%RANDOM%_%RANDOM%"
if not exist "!TEST_TMP!" mkdir "!TEST_TMP!"

echo === 1. Test uuid_gen.cmd Determinism ===
set "_U1="
set "_U2="
for /f "usebackq delims=" %%U in (`call "!LIBSCRIPT_ROOT_DIR!!_BS!engine!_BS!common!_BS!uuid_gen.cmd" "demo-seed"`) do set "_U1=%%U"
for /f "usebackq delims=" %%U in (`call "!LIBSCRIPT_ROOT_DIR!!_BS!engine!_BS!common!_BS!uuid_gen.cmd" "demo-seed"`) do set "_U2=%%U"
if "!_U1!"=="" ( echo [FAIL] uuid_gen.cmd returned empty output 1>&2 & goto :cleanup_fail )
if not "!_U1!"=="!_U2!" ( echo [FAIL] uuid_gen.cmd non-deterministic: !_U1! vs !_U2! 1>&2 & goto :cleanup_fail )

echo === 2. Test Topology Engine 2x Idempotency, Scale, Drain, Failover, Upgrade, Destroy ===
> "!TEST_TMP!!_BS!topo.json" echo {"name":"win-std-cluster","substrate":{"provider":"local"},"node_groups":[{"name":"db","count":2,"roles":["leader","follower"]}]}
set "LIBSCRIPT_TOPOLOGY_STATE_DIR=!TEST_TMP!!_BS!state"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!constellations!_BS!engine.cmd" up "!TEST_TMP!!_BS!topo.json" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!constellations!_BS!engine.cmd" up "!TEST_TMP!!_BS!topo.json" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!constellations!_BS!engine.cmd" scale "!TEST_TMP!!_BS!topo.json" "db=3" >nul
if errorlevel 1 goto :cleanup_fail
jq -e --arg gn "db" "[.nodes[] | select(.group == $gn)] | length == 3" "!LIBSCRIPT_TOPOLOGY_STATE_DIR!!_BS!.topology_state.json" >nul
if errorlevel 1 ( echo [FAIL] Expected 3 db nodes after scale 1>&2 & goto :cleanup_fail )
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!constellations!_BS!engine.cmd" drain "!TEST_TMP!!_BS!topo.json" db-2 >nul
if errorlevel 1 goto :cleanup_fail
jq -e --arg nid "db-2" --arg st "DRAINED" ".nodes[] | select(.id == $nid) | .state == $st" "!LIBSCRIPT_TOPOLOGY_STATE_DIR!!_BS!.topology_state.json" >nul
if errorlevel 1 ( echo [FAIL] Expected db-2 DRAINED 1>&2 & goto :cleanup_fail )
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!constellations!_BS!engine.cmd" failover "!TEST_TMP!!_BS!topo.json" db-0 >nul
if errorlevel 1 goto :cleanup_fail
jq -e --arg nid "db-0" --arg st "FENCED" ".nodes[] | select(.id == $nid) | .state == $st" "!LIBSCRIPT_TOPOLOGY_STATE_DIR!!_BS!.topology_state.json" >nul
if errorlevel 1 ( echo [FAIL] Expected db-0 FENCED after failover 1>&2 & goto :cleanup_fail )
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!constellations!_BS!engine.cmd" upgrade "!TEST_TMP!!_BS!topo.json" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!constellations!_BS!engine.cmd" destroy "!TEST_TMP!!_BS!topo.json" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!constellations!_BS!engine.cmd" destroy "!TEST_TMP!!_BS!topo.json" >nul
if errorlevel 1 goto :cleanup_fail

echo === 3. Test Payload Schedulers (native, nomad, slurm_ray) ===
> "!TEST_TMP!!_BS!payload.json" echo {"name":"demo-worker","type":"service","artifact":{"format":"oci-image","image":"alpine:3.20","entrypoint":["cmd.exe","/c","echo"]},"resources":{"cpu_cores":2,"memory_mb":512,"gpu_count":1},"scaling":{"replicas":2}}
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!schedulers!_BS!native.cmd" compile "!TEST_TMP!!_BS!payload.json" --init sc >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!schedulers!_BS!nomad.cmd" compile "!TEST_TMP!!_BS!payload.json" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!workloads!_BS!schedulers!_BS!slurm_ray.cmd" compile "!TEST_TMP!!_BS!payload.json" >nul
if errorlevel 1 goto :cleanup_fail

echo === 4. Test Experiment Scaffold 2x Idempotency ===
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!experiments!_BS!cli!_BS!scaffold.cmd" demo-win-suite "--out-root=!TEST_TMP!!_BS!exps" >nul
if errorlevel 1 goto :cleanup_fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!experiments!_BS!cli!_BS!scaffold.cmd" demo-win-suite "--out-root=!TEST_TMP!!_BS!exps" >nul
if errorlevel 1 goto :cleanup_fail

echo === 5. Test Audit Allowlist ^& MSI Harvest Regex Parity ===
findstr /C:"_lib/(_common" /C:"web-apps/.*/" /C:"orchestration/distro/" "!LIBSCRIPT_ROOT_DIR!!_BS!devtools!_BS!audit!_BS!audit_standards.ps1" >nul 2>&1
if not errorlevel 1 ( echo [FAIL] Stale 5-tier allowlist regex found in audit_standards.ps1 1>&2 & goto :cleanup_fail )
findstr /C:"engine/common/(pkg_mgr|daemonize)" "!LIBSCRIPT_ROOT_DIR!!_BS!devtools!_BS!audit!_BS!audit_standards.ps1" >nul 2>&1
if errorlevel 1 ( echo [FAIL] Missing engine/common allowlist in audit_standards.ps1 1>&2 & goto :cleanup_fail )
findstr /C:"workloads/services/" "!LIBSCRIPT_ROOT_DIR!!_BS!devtools!_BS!audit!_BS!audit_standards.ps1" >nul 2>&1
if errorlevel 1 ( echo [FAIL] Missing workloads/services allowlist in audit_standards.ps1 1>&2 & goto :cleanup_fail )
findstr /C:"synthesis\msi\/" "!LIBSCRIPT_ROOT_DIR!!_BS!synthesis!_BS!msi!_BS!harvest_payload.cmd" >nul 2>&1
if not errorlevel 1 ( echo [FAIL] Malformed gawk \m escape found in harvest_payload.cmd 1>&2 & goto :cleanup_fail )

echo === 6. Test GitHub HTTP 403 Authenticated Rescue ^& Checksum DB Guard ===
set "GH_TDIR=!TEST_TMP!!_BS!gh_403"
set "GH_SHIMS=!GH_TDIR!!_BS!shims"
set "GH_DL=!GH_TDIR!!_BS!dl"
if not exist "!GH_SHIMS!" mkdir "!GH_SHIMS!"
if not exist "!GH_DL!" mkdir "!GH_DL!"
> "!GH_TDIR!!_BS!fixture.bin" echo verified-github-release-win32-payload
> "!GH_TDIR!!_BS!checksums.txt" echo # mock checksum db

(
    echo @echo off
    echo echo curl: ^(56^) The requested URL returned error: 403 1^>^&2
    echo exit /b 56
) > "!GH_SHIMS!!_BS!curl.cmd"

(
    echo @echo off
    echo exit /b 8
) > "!GH_SHIMS!!_BS!wget.cmd"

(
    echo @echo off
    echo if /i not "%%GH_TOKEN%%"=="mock-ci-token" exit /b 1
    echo set "_G_PAT="
    echo set "_G_DIR="
    echo :gh_arg_loop
    echo if "%%~1"=="" goto :gh_arg_done
    echo if "%%~1"=="-p" ^( set "_G_PAT=%%~2" ^& shift ^& shift ^& goto :gh_arg_loop ^)
    echo if "%%~1"=="-D" ^( set "_G_DIR=%%~2" ^& shift ^& shift ^& goto :gh_arg_loop ^)
    echo shift
    echo goto :gh_arg_loop
    echo :gh_arg_done
    echo if "%%_G_DIR%%"=="" exit /b 1
    echo if "%%_G_PAT%%"=="" exit /b 1
    echo copy /y "!GH_TDIR!!_BS!fixture.bin" "%%_G_DIR%%\%%_G_PAT%%" ^>nul
    echo exit /b 0
) > "!GH_SHIMS!!_BS!gh.cmd"

set "_SAVED_PATH=!PATH!"
set "PATHEXT=.CMD;.BAT;.EXE;.COM"
set "PATH=!GH_SHIMS!;!PATH!"
set "GITHUB_TOKEN=mock-ci-token"
set "GH_TOKEN="
set "DOWNLOAD_DIR=!GH_DL!"
set "LIBSCRIPT_CACHE_DIR=!GH_DL!"
set "LIBSCRIPT_CHECKSUM_DB=!GH_TDIR!!_BS!checksums.txt"
set "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1"
set "LIBSCRIPT_DOWNLOAD_RETRIES=1"
set "LIBSCRIPT_DOWNLOAD_RETRY_DELAY=0"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!!_BS!engine!_BS!common!_BS!pkg_mgr.cmd" :libscript_download "https://github.com/SamuelMarks/win-cmd-rs/releases/download/v9.9.9/mock-win-asset.zip" "!GH_TDIR!!_BS!out.zip"
set "_GH_DL_RC=!ERRORLEVEL!"
set "PATH=!_SAVED_PATH!"
set "GITHUB_TOKEN="
set "GH_TOKEN="
set "DOWNLOAD_DIR="
set "LIBSCRIPT_CACHE_DIR="
set "LIBSCRIPT_CHECKSUM_DB="
set "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB="
set "LIBSCRIPT_DOWNLOAD_RETRIES="
set "LIBSCRIPT_DOWNLOAD_RETRY_DELAY="
if not "!_GH_DL_RC!"=="0" ( echo [FAIL] Expected pkg_mgr.cmd :libscript_download to rescue HTTP 403 via gh release download 1>&2 & goto :cleanup_fail )
if not exist "!GH_TDIR!!_BS!out.zip" ( echo [FAIL] Expected rescued artifact at out.zip 1>&2 & goto :cleanup_fail )
findstr /C:"mock-win-asset.zip" "!GH_TDIR!!_BS!checksums.txt" >nul 2>&1
if not errorlevel 1 ( echo [FAIL] LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 failed to protect checksums.txt 1>&2 & goto :cleanup_fail )

echo === 7. Test make.bat Delegation ^& Standards Auditor Rules ===
findstr /C:"make.cmd" "!LIBSCRIPT_ROOT_DIR!!_BS!make.bat" >nul 2>&1
if errorlevel 1 ( echo [FAIL] Expected make.bat to delegate directly to make.cmd 1>&2 & goto :cleanup_fail )
findstr /C:"unzip_no_o_hits" "!LIBSCRIPT_ROOT_DIR!!_BS!devtools!_BS!audit!_BS!audit_standards.sh" >nul 2>&1
if errorlevel 1 ( echo [FAIL] Expected unzip_no_o_hits rule in audit_standards.sh 1>&2 & goto :cleanup_fail )
findstr /C:"stale_mklink_hits" "!LIBSCRIPT_ROOT_DIR!!_BS!devtools!_BS!audit!_BS!audit_standards.sh" >nul 2>&1
if errorlevel 1 ( echo [FAIL] Expected stale_mklink_hits rule in audit_standards.sh 1>&2 & goto :cleanup_fail )

if exist "!TEST_TMP!" rmdir /s /q "!TEST_TMP!" >nul 2>&1
echo [PASS] All Windows standards adherence regression tests succeeded.
exit /b 0

:: ## cleanup_fail
:: Cleans temporary test directory and exits with failure status 1.
:cleanup_fail
if exist "!TEST_TMP!" rmdir /s /q "!TEST_TMP!" >nul 2>&1
echo [FAIL] Windows standards adherence regression test failed. 1>&2
exit /b 1
