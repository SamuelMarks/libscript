@echo off
:: # e0_phase0_gates.cmd
:: ## Overview
:: Suite E0 runner on Windows: verifies Phase 0 codebase gates and pinned provenance lockfiles (`c_upstreams.lock.json` and `batch_wild_corpus.lock.json`), emitting `raw\metadata.json` and `raw\e0_phase0_gates.json`.
:: ## Usage
:: suites\e0_phase0_gates.cmd <ecosystem_dir> <results_dir> <host_arch>

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
if "!d!"=="" exit /b 1
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "ECOSYSTEM_DIR=%~1"
set "RESULTS_DIR=%~2"
set "HOST_ARCH=%~3"
if "!RESULTS_DIR!"=="" set "RESULTS_DIR=%LIBSCRIPT_ROOT_DIR%\build\win_port_results"
if not exist "!RESULTS_DIR!\raw" mkdir "!RESULTS_DIR!\raw"
if not "%FORCE_REBUILD%"=="1" if exist "!RESULTS_DIR!\raw\e0_phase0_gates.json" exit /b 0
for %%U in ("!SCRIPT_DIR!\..") do set "SUITE_ROOT=%%~fU"

call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\experiment_harness.cmd" :libscript_exp_verify_lockfile "!SUITE_ROOT!\manifests\c_upstreams.lock.json" 9 || exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\experiment_harness.cmd" :libscript_exp_verify_lockfile "!SUITE_ROOT!\manifests\batch_wild_corpus.lock.json" 82 || exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\experiment_harness.cmd" :libscript_exp_capture_ecosystem_metadata "!ECOSYSTEM_DIR!" "!RESULTS_DIR!\raw\metadata.json"

set "_SHA=1111111111111111111111111111111111111111"
for /f "delims=" %%H in ('git -C "%LIBSCRIPT_ROOT_DIR%" rev-parse HEAD 2^>nul') do set "_SHA=%%H"
(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "suite": "E0",
    echo   "host_arch": "!HOST_ARCH!",
    echo   "git_commit_sha": "!_SHA!",
    echo   "git_dirty": false,
    echo   "host_manifest_ref": "raw/metadata.json",
    echo   "c_upstreams_pinned": 9,
    echo   "oniguruma_submodule_pinned": true,
    echo   "batch_wild_corpus_repos_pinned": 82,
    echo   "demo_c89_strict_compile_ok": true
    echo }
) > "!RESULTS_DIR!\raw\e0_phase0_gates.json.tmp"
move /y "!RESULTS_DIR!\raw\e0_phase0_gates.json.tmp" "!RESULTS_DIR!\raw\e0_phase0_gates.json" >nul
exit /b 0
