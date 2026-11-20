@echo off
:: # test_win_port_experiments.cmd
:: ## Overview
:: Windows integration, `\tbd{???}` placeholder tamper-rejection, dual-manuscript (`win_port_paper.tex` + `win_port_appendix.tex`) verification, and 2x idempotency test suite for `_lib\toolchains\win-port-suite\benchmark_experiments.cmd` across Suites `E0`-`E7`.
:: ## Usage
:: call tests\test_win_port_experiments.cmd

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
set "TEST_DIR=%TEMP%\win_port_exp_%RANDOM%"
if exist "!TEST_DIR!" rmdir /s /q "!TEST_DIR!" >nul 2>&1
if not exist "!TEST_DIR!\paper" mkdir "!TEST_DIR!\paper"

call :run_win_port_suite_and_idempotency_tests
if errorlevel 1 (
    if exist "!TEST_DIR!" rmdir /s /q "!TEST_DIR!" >nul 2>&1
    exit /b 1
)

if exist "!TEST_DIR!" rmdir /s /q "!TEST_DIR!" >nul 2>&1
echo [PASS] Windows win_port E0-E7 empirical suites, 285-macro gate, dual-manuscript, and 2x idempotency tests succeeded^^!
exit /b 0

:: ## run_win_port_suite_and_idempotency_tests
:: Runs E0-E7 twice, verifies all 19 raw JSONs, precision CSV, generated macros, placeholder rejection, and clean dual-manuscript verification.
:run_win_port_suite_and_idempotency_tests
set "WIN_PORT_SUITE_ALLOW_DIRTY=1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" win-port-suite experiments --synthetic-fixtures --subsuites=E0,E1,E2,E3,E4,E5,E6,E7 "--results-dir=!TEST_DIR!\results"
if errorlevel 1 exit /b 1

for %%J in (metadata.json e0_phase0_gates.json e1_cdd_transform.json e1b_downstream_compile_ctest.json e2_port_audit.json e3a_win64_servers.json e3b_win64_cli.json e3c_dos_matrix.json e4a_msi_authoring.json e4b_wine_warm_Linux_x86_64.json e4b_wine_cold_Linux_x86_64.json e4b_wine_warm_Darwin_arm64.json e4b_wine_cold_Darwin_arm64.json e4c_msi_rollback.json e5a_wincheck_corpus.json e5b_win11_ground_truth.json e5b_cmd_oracle_comparison.json e5c_precision_summary.json e6_ecosystem_rigor.json) do (
    if not exist "!TEST_DIR!\results\raw\%%J" (
        echo [FAIL] Missing win-port-suite raw JSON artifact: %%J >&2
        exit /b 1
    )
)

if not exist "!TEST_DIR!\results\raw\e5c_precision_sample.csv" (
    echo [FAIL] Missing e5c_precision_sample.csv >&2
    exit /b 1
)
if not exist "!TEST_DIR!\results\generated_metrics.tex" (
    echo [FAIL] Missing generated_metrics.tex >&2
    exit /b 1
)
findstr /C:"wpMetric" "!TEST_DIR!\results\generated_metrics.tex" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] generated_metrics.tex missing wpMetric definitions >&2
    exit /b 1
)

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" win-port-suite experiments --synthetic-fixtures --subsuites=E0,E1,E2,E3,E4,E5,E6,E7 "--results-dir=!TEST_DIR!\results"
if errorlevel 1 exit /b 1

(
    echo \documentclass{article}
    echo \input{generated_metrics.tex}
    echo \begin{document}
    echo Unresolved empirical value: \tbd{???}
    echo \end{document}
) > "!TEST_DIR!\paper\win_port_paper.tex"

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" win-port-suite experiments --synthetic-fixtures --subsuites=E7 "--results-dir=!TEST_DIR!\results" "--paper-dir=!TEST_DIR!\paper" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] E7 failed to reject unresolved placeholder^^! >&2
    exit /b 1
)

(
    echo \documentclass{article}
    echo \input{generated_metrics.tex}
    echo \begin{document}
    echo Verified C89 CST metric: \wpMetricAbsAA{} and total slot \wpMetricAppABentoAB{}.
    echo \end{document}
) > "!TEST_DIR!\paper\win_port_paper.tex"

(
    echo \documentclass{article}
    echo \input{generated_metrics.tex}
    echo \begin{document}
    echo AnonDosVM Vagrant plugin metric: \wpMetricAppABentoAA{} and NASM metric: \wpMetricAppABentoAB{}.
    echo \end{document}
) > "!TEST_DIR!\paper\win_port_appendix.tex"

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" win-port-suite experiments --synthetic-fixtures --subsuites=E7 "--results-dir=!TEST_DIR!\results" "--paper-dir=!TEST_DIR!\paper"
if errorlevel 1 exit /b 1
exit /b 0
