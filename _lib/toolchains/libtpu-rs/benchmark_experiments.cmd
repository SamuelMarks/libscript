@echo off
:: # benchmark_experiments.cmd
:: ## Overview
:: Master idempotent empirical evaluation orchestrator (`benchmark_experiments.cmd`) on Windows for `libtpu-rs` / `libtpu_paper`, routing sub-suites `E0` through `E8`.
:: ## Usage
:: _lib\toolchains\libtpu-rs\benchmark_experiments.cmd [--subsuites=E0..E8] [--warmup=10] [--trials=200] [--results-dir=...] [--repo-dir=...] [--paper-dir=...]

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" exit /b 1
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
if "%LIBTPU_RS_SUBSUITES%"=="" set "LIBTPU_RS_SUBSUITES=E0,E1,E2,E3,E4,E5,E6,E7,E8"
if "%LIBTPU_RS_WARMUP%"=="" set "LIBTPU_RS_WARMUP=10"
if "%LIBTPU_RS_TRIALS%"=="" set "LIBTPU_RS_TRIALS=200"
if "%LIBTPU_RS_RESULTS_DIR%"=="" set "LIBTPU_RS_RESULTS_DIR=!LIBSCRIPT_ROOT_DIR!\build\libtpu_results"
if "%LIBTPU_RS_REPO_DIR%"=="" set "LIBTPU_RS_REPO_DIR=!LIBSCRIPT_ROOT_DIR!"
if "%LIBTPU_RS_PAPER_DIR%"=="" set "LIBTPU_RS_PAPER_DIR="
if "%LIBTPU_RS_HOST_ARCH%"=="" set "LIBTPU_RS_HOST_ARCH=windows_x64"
if "%LIBTPU_RS_BUILD_PDF%"=="" set "LIBTPU_RS_BUILD_PDF=0"

for %%A in (%*) do (
    set "_a=%%~A"
    if "!_a:~0,12!"=="--subsuites=" set "LIBTPU_RS_SUBSUITES=!_a:~12!"
    if "!_a:~0,9!"=="--warmup=" set "LIBTPU_RS_WARMUP=!_a:~9!"
    if "!_a:~0,9!"=="--trials=" set "LIBTPU_RS_TRIALS=!_a:~9!"
    if "!_a:~0,14!"=="--results-dir=" set "LIBTPU_RS_RESULTS_DIR=!_a:~14!"
    if "!_a:~0,10!"=="--out-dir=" set "LIBTPU_RS_RESULTS_DIR=!_a:~10!"
    if "!_a:~0,11!"=="--repo-dir=" set "LIBTPU_RS_REPO_DIR=!_a:~11!"
    if "!_a:~0,12!"=="--paper-dir=" set "LIBTPU_RS_PAPER_DIR=!_a:~12!"
    if "!_a:~0,12!"=="--host-arch=" set "LIBTPU_RS_HOST_ARCH=!_a:~12!"
    if /i "!_a!"=="--build-pdf" set "LIBTPU_RS_BUILD_PDF=1"
    if /i "!_a!"=="--synthetic-fixtures" set "LIBTPU_RS_SYNTHETIC_FIXTURES=1"
    if /i "!_a!"=="--allow-dirty" set "LIBTPU_RS_ALLOW_DIRTY=1"
    if /i "!_a!"=="--force" set "FORCE_REBUILD=1"
)

if not exist "!LIBTPU_RS_RESULTS_DIR!" mkdir "!LIBTPU_RS_RESULTS_DIR!"
set "_SLIST=!LIBTPU_RS_SUBSUITES:,= !"
for %%S in (!_SLIST!) do (
    if /i "%%S"=="E0" call "!SCRIPT_DIR!\suites\e0_provenance.cmd" "!LIBTPU_RS_REPO_DIR!" "!LIBTPU_RS_RESULTS_DIR!" "!LIBTPU_RS_HOST_ARCH!"
    if /i "%%S"=="E1" call "!SCRIPT_DIR!\suites\e1_forensics.cmd" "!LIBTPU_RS_REPO_DIR!" "!LIBTPU_RS_RESULTS_DIR!" "!LIBTPU_RS_HOST_ARCH!"
    if /i "%%S"=="E2" call "!SCRIPT_DIR!\suites\e2_footprint_startup.cmd" "!LIBTPU_RS_REPO_DIR!" "!LIBTPU_RS_RESULTS_DIR!" "!LIBTPU_RS_HOST_ARCH!" "!LIBTPU_RS_WARMUP!" "!LIBTPU_RS_TRIALS!"
    if /i "%%S"=="E3" call "!SCRIPT_DIR!\suites\e3_jax_e2e.cmd" "!LIBTPU_RS_REPO_DIR!" "!LIBTPU_RS_RESULTS_DIR!" "!LIBTPU_RS_HOST_ARCH!"
    if /i "%%S"=="E4" call "!SCRIPT_DIR!\suites\e4_compiler_aot.cmd" "!LIBTPU_RS_REPO_DIR!" "!LIBTPU_RS_RESULTS_DIR!" "!LIBTPU_RS_HOST_ARCH!" "!LIBTPU_RS_TRIALS!"
    if /i "%%S"=="E5" call "!SCRIPT_DIR!\suites\e5_memory_studies.cmd" "!LIBTPU_RS_REPO_DIR!" "!LIBTPU_RS_RESULTS_DIR!" "!LIBTPU_RS_HOST_ARCH!"
    if /i "%%S"=="E6" call "!SCRIPT_DIR!\suites\e6_vliw_ablations.cmd" "!LIBTPU_RS_REPO_DIR!" "!LIBTPU_RS_RESULTS_DIR!" "!LIBTPU_RS_HOST_ARCH!"
    if /i "%%S"=="E7" call "!SCRIPT_DIR!\suites\e7_numerics_sparsecore.cmd" "!LIBTPU_RS_REPO_DIR!" "!LIBTPU_RS_RESULTS_DIR!" "!LIBTPU_RS_HOST_ARCH!"
    if /i "%%S"=="E8" call "!SCRIPT_DIR!\suites\e8_latex.cmd" "!LIBTPU_RS_RESULTS_DIR!" "!LIBTPU_RS_PAPER_DIR!" "!LIBTPU_RS_BUILD_PDF!"
    if errorlevel 1 exit /b 1
)
(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "suite": "libtpu",
    echo   "subsuites": "!LIBTPU_RS_SUBSUITES!",
    echo   "host_arch": "!LIBTPU_RS_HOST_ARCH!",
    echo   "status": "PASS"
    echo }
) > "!LIBTPU_RS_RESULTS_DIR!\campaign_summary.json.tmp"
move /y "!LIBTPU_RS_RESULTS_DIR!\campaign_summary.json.tmp" "!LIBTPU_RS_RESULTS_DIR!\campaign_summary.json" >nul
exit /b 0
