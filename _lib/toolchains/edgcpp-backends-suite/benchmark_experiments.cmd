@echo off
:: # benchmark_experiments.cmd
:: ## Overview
:: Master idempotent empirical evaluation orchestrator (`benchmark_experiments.cmd`) for `edgcpp_backends` on Windows, routing sub-suites `E0` through `E7`.
:: ## Usage
:: _lib\toolchains\edgcpp-backends-suite\benchmark_experiments.cmd [--subsuites=E0..E7] [--repo=...] [--results-dir=...] [--paper-dir=...] [--host-arch=...] [--synthetic-fixtures] [--build-pdf]

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
if "%EDGCPP_BACKENDS_SUITE_SUBSUITES%"=="" set "EDGCPP_BACKENDS_SUITE_SUBSUITES=E0,E1,E2,E3,E4,E5,E6,E7"
if "%EDGCPP_BACKENDS_SUITE_REPO%"=="" set "EDGCPP_BACKENDS_SUITE_REPO=C:\repos\edgcpp-compiler-multibackend"
if "%EDGCPP_BACKENDS_SUITE_RESULTS_DIR%"=="" set "EDGCPP_BACKENDS_SUITE_RESULTS_DIR=!LIBSCRIPT_ROOT_DIR!\build\edgcpp_backends_results"
if "%EDGCPP_BACKENDS_SUITE_HOST_ARCH%"=="" set "EDGCPP_BACKENDS_SUITE_HOST_ARCH=windows_x64"
if "%EDGCPP_BACKENDS_SUITE_SYNTHETIC%"=="" set "EDGCPP_BACKENDS_SUITE_SYNTHETIC=0"
if "%EDGCPP_BACKENDS_SUITE_BUILD_PDF%"=="" set "EDGCPP_BACKENDS_SUITE_BUILD_PDF=0"

for %%A in (%*) do (
    set "_a=%%~A"
    if "!_a:~0,12!"=="--subsuites=" set "EDGCPP_BACKENDS_SUITE_SUBSUITES=!_a:~12!"
    if "!_a:~0,7!"=="--repo=" set "EDGCPP_BACKENDS_SUITE_REPO=!_a:~7!"
    if "!_a:~0,14!"=="--results-dir=" set "EDGCPP_BACKENDS_SUITE_RESULTS_DIR=!_a:~14!"
    if "!_a:~0,12!"=="--paper-dir=" set "EDGCPP_BACKENDS_SUITE_PAPER_DIR=!_a:~12!"
    if "!_a:~0,12!"=="--host-arch=" set "EDGCPP_BACKENDS_SUITE_HOST_ARCH=!_a:~12!"
    if /I "!_a!"=="--synthetic-fixtures" set "EDGCPP_BACKENDS_SUITE_SYNTHETIC=1"
    if /I "!_a!"=="--allow-dirty" set "EDGCPP_BACKENDS_SUITE_ALLOW_DIRTY=1"
    if /I "!_a!"=="--dry-run" exit /b 0
    if /I "!_a!"=="--build-pdf" set "EDGCPP_BACKENDS_SUITE_BUILD_PDF=1"
    if /I "!_a!"=="--force" set "FORCE_REBUILD=1"
)

if not exist "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!\raw" mkdir "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!\raw"
set "_S_LIST=!EDGCPP_BACKENDS_SUITE_SUBSUITES:,= !"
for %%S in (!_S_LIST!) do (
    if /I "%%S"=="E0" call "!SCRIPT_DIR!\suites\e0_phase0_gates.cmd" "!EDGCPP_BACKENDS_SUITE_REPO!" "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!" "!EDGCPP_BACKENDS_SUITE_HOST_ARCH!" || exit /b 1
    if /I "%%S"=="E1" call "!SCRIPT_DIR!\suites\e1_compile_perf.cmd" "!EDGCPP_BACKENDS_SUITE_REPO!" "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!" "!EDGCPP_BACKENDS_SUITE_HOST_ARCH!" || exit /b 1
    if /I "%%S"=="E2" call "!SCRIPT_DIR!\suites\e2_sqlite_ablation.cmd" "!EDGCPP_BACKENDS_SUITE_REPO!" "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!" "!EDGCPP_BACKENDS_SUITE_HOST_ARCH!" || exit /b 1
    if /I "%%S"=="E3" call "!SCRIPT_DIR!\suites\e3_eh_unwinding.cmd" "!EDGCPP_BACKENDS_SUITE_REPO!" "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!" "!EDGCPP_BACKENDS_SUITE_HOST_ARCH!" || exit /b 1
    if /I "%%S"=="E4" call "!SCRIPT_DIR!\suites\e4_coroutines.cmd" "!EDGCPP_BACKENDS_SUITE_REPO!" "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!" "!EDGCPP_BACKENDS_SUITE_HOST_ARCH!" || exit /b 1
    if /I "%%S"=="E5" call "!SCRIPT_DIR!\suites\e5_abi_and_fuzz.cmd" "!EDGCPP_BACKENDS_SUITE_REPO!" "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!" "!EDGCPP_BACKENDS_SUITE_HOST_ARCH!" || exit /b 1
    if /I "%%S"=="E6" call "!SCRIPT_DIR!\suites\e6_corpus_and_kernel.cmd" "!EDGCPP_BACKENDS_SUITE_REPO!" "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!" "!EDGCPP_BACKENDS_SUITE_HOST_ARCH!" || exit /b 1
    if /I "%%S"=="E7" call "!SCRIPT_DIR!\suites\e7_latex_verify.cmd" "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!" "!EDGCPP_BACKENDS_SUITE_PAPER_DIR!" "!EDGCPP_BACKENDS_SUITE_BUILD_PDF!" || exit /b 1
    if /I "%%S"=="E8" call "!SCRIPT_DIR!\suites\e7_latex_verify.cmd" "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!" "!EDGCPP_BACKENDS_SUITE_PAPER_DIR!" "!EDGCPP_BACKENDS_SUITE_BUILD_PDF!" || exit /b 1
)
(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "suite": "edgcpp_backends",
    echo   "subsuites": "!EDGCPP_BACKENDS_SUITE_SUBSUITES!",
    echo   "host_arch": "!EDGCPP_BACKENDS_SUITE_HOST_ARCH!",
    echo   "total_placeholders_governed": 60,
    echo   "status": "PASS"
    echo }
) > "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!\campaign_summary.json.tmp"
move /y "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!\campaign_summary.json.tmp" "!EDGCPP_BACKENDS_SUITE_RESULTS_DIR!\campaign_summary.json" >nul
exit /b 0
