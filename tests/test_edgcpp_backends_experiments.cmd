@echo off
:: # test_edgcpp_backends_experiments.cmd
:: ## Overview
:: Comprehensive Windows unit, integration, 2x byte-identical idempotency, driver, and negative integrity-gate test suite for `edgcpp-backends-suite` (E0-E7).
:: ## Usage
:: call tests\test_edgcpp_backends_experiments.cmd

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
set "WORK_DIR=%TEMP%\test_edgcpp_backends_%RANDOM%"
if exist "!WORK_DIR!" rmdir /s /q "!WORK_DIR!" >nul 2>&1
if not exist "!WORK_DIR!" mkdir "!WORK_DIR!"

call :test_full_e0_to_e7_and_2x_idempotency
if errorlevel 1 goto :fail_out

call :test_driver_smoke
if errorlevel 1 goto :fail_out

call :test_negative_integrity_gates
if errorlevel 1 goto :fail_out

if exist "!WORK_DIR!" rmdir /s /q "!WORK_DIR!" >nul 2>&1
echo [PASS] All edgcpp_backends Windows E0-E7 empirical, idempotency, driver, and negative-gate tests succeeded^^!
exit /b 0

:: ## fail_out
:: Cleans up temporary directory and exits non-zero on test failure.
:fail_out
if exist "!WORK_DIR!" rmdir /s /q "!WORK_DIR!" >nul 2>&1
exit /b 1

:: ## test_full_e0_to_e7_and_2x_idempotency
:: Executes E0-E7 twice, verifies all 13 raw JSON files and generated_metrics.tex, and asserts byte-identical 2x idempotency.
:test_full_e0_to_e7_and_2x_idempotency
set "_RES=!WORK_DIR!\run_results"
set "_PAPER=!WORK_DIR!\paper_clean"
if not exist "!_PAPER!" mkdir "!_PAPER!"
(
    echo \documentclass{article}
    echo \begin{document}
    echo Coverage is \EdgGccBeCovLinePct\%% and psABI passed \EdgPsabiFuzzPassedOfThousand/1,000.
    echo \end{document}
) > "!_PAPER!\edgecpp_backends.tex"

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment run edgcpp-backends --synthetic-fixtures "--results-dir=!_RES!" "--paper-dir=!_PAPER!"
if errorlevel 1 exit /b 1

for %%J in (metadata.json exp0_coverage.json exp0_bug4_ablation.json exp1_compile_perf.json exp2_sqlite_runtime.json exp2_ablation.json exp3_eh.json exp4_coro.json exp5_abi_fuzz.json exp5_gcc_torture.json exp5_diff_fuzz.json exp6_projects.json exp6_kernel.json) do (
    if not exist "!_RES!\raw\%%J" (
        echo [FAIL] Missing expected raw JSON artifact: %%J >&2
        exit /b 1
    )
)

if not exist "!_RES!\generated_metrics.tex" (
    echo [FAIL] Missing generated_metrics.tex >&2
    exit /b 1
)
copy /y "!_RES!\generated_metrics.tex" "!WORK_DIR!\metrics_run1.tex" >nul

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment run edgcpp-backends --synthetic-fixtures "--results-dir=!_RES!" "--paper-dir=!_PAPER!"
if errorlevel 1 exit /b 1

fc /b "!WORK_DIR!\metrics_run1.tex" "!_RES!\generated_metrics.tex" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] 2x rerun did not produce byte-identical generated_metrics.tex >&2
    exit /b 1
)
exit /b 0

:: ## test_driver_smoke
:: Runs the edgcpp component smoke test companion on Windows.
:test_driver_smoke
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\languages\edgcpp\test.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\edgcpp\test.cmd"
    if errorlevel 1 exit /b 1
)
exit /b 0

:: ## test_negative_integrity_gates
:: Verifies dirty git worktree rejection, non-Linux Kbuild refusal, and unresolved placeholder rejection.
:test_negative_integrity_gates
set "_DIRTY=!WORK_DIR!\dirty_edg"
if not exist "!_DIRTY!" mkdir "!_DIRTY!"
pushd "!_DIRTY!"
git init -q
git config user.email "ci@libscript.local"
git config user.name "LibScript CI"
echo int x = 1;> a.c
git add a.c
git commit -q -m "init"
echo int x = 2;> a.c
popd

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\experiments\edgcpp-backends\suites\e0_phase0_gates.cmd" "!_DIRTY!" "!WORK_DIR!\dirty_out" "windows_x64" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] E0 accepted dirty git worktree^^! >&2
    exit /b 1
)

set "EDGCPP_BACKENDS_SUITE_SYNTHETIC=0"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\experiments\edgcpp-backends\suites\e6_corpus_and_kernel.cmd" "C:\none" "!WORK_DIR!\bad_k" "windows_x64" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] E6 allowed fake Linux kernel Kbuild on Windows^^! >&2
    exit /b 1
)

set "_BAD_PAPER=!WORK_DIR!\paper_tbd"
if not exist "!_BAD_PAPER!" mkdir "!_BAD_PAPER!"
(
    echo \documentclass{article}
    echo \begin{document}
    echo Latency is \tbd s ^(???^).
    echo \end{document}
) > "!_BAD_PAPER!\edgecpp_backends.tex"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\experiments\edgcpp-backends\suites\e7_latex_verify.cmd" "!WORK_DIR!\run_results" "!_BAD_PAPER!" "0" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] E7 accepted unresolved placeholder in edgecpp_backends.tex^^! >&2
    exit /b 1
)
exit /b 0
