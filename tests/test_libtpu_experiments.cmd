@echo off
:: # test_libtpu_experiments.cmd
:: ## Overview
:: End-to-end Windows integration, 2x idempotency, safe-core `unsafe == 0` gate, and `\tbd` placeholder rejection test suite for `_lib\toolchains\libtpu-rs\benchmark_experiments.cmd` across Suites `E0`-`E8`.
:: ## Usage
:: call tests\test_libtpu_experiments.cmd

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
set "WORK_DIR=%TEMP%\libtpu_exp_win_%RANDOM%"
if exist "!WORK_DIR!" rmdir /s /q "!WORK_DIR!" >nul 2>&1
if not exist "!WORK_DIR!\paper_clean" mkdir "!WORK_DIR!\paper_clean"
if not exist "!WORK_DIR!\paper_tbd" mkdir "!WORK_DIR!\paper_tbd"

(
    echo \documentclass{article}
    echo \input{generated_metrics.tex}
    echo \begin{document}
    echo Warm client init: \MetricWarmClientInitMedMs{} ms.
    echo \end{document}
) > "!WORK_DIR!\paper_clean\libtpu_paper.tex"

(
    echo \documentclass{article}
    echo \begin{document}
    echo Unresolved placeholder: \tbd and ???
    echo \end{document}
) > "!WORK_DIR!\paper_tbd\libtpu_paper.tex"

call :test_full_e0_to_e8_and_2x_idempotency
if errorlevel 1 goto :fail_out

call :test_tbd_placeholder_and_unsafe_gates
if errorlevel 1 goto :fail_out

if exist "!WORK_DIR!" rmdir /s /q "!WORK_DIR!" >nul 2>&1
echo [PASS] Windows libtpu-rs E0-E8 empirical suites, gates, and 2x idempotency tests succeeded^^!
exit /b 0

:: ## fail_out
:: Removes temporary workspace and exits non-zero on failure.
:fail_out
if exist "!WORK_DIR!" rmdir /s /q "!WORK_DIR!" >nul 2>&1
exit /b 1

:: ## test_full_e0_to_e8_and_2x_idempotency
:: Executes Suites E0-E8 twice consecutively and verifies all 16 JSON/TeX outputs and cached 2x idempotency.
:test_full_e0_to_e8_and_2x_idempotency
set "_RES=!WORK_DIR!\results"
set "LIBTPU_RS_ALLOW_DIRTY=1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" libtpu-rs experiments --synthetic-fixtures --subsuites=E0,E1,E2,E3,E4,E5,E6,E7,E8 --warmup=2 --trials=5 "--results-dir=!_RES!" "--paper-dir=!WORK_DIR!\paper_clean"
if errorlevel 1 exit /b 1

for %%R in (e0_wheel_provenance.json e0_tcb.json e1_abi_parity.json e1_disasm.json e1_carver.json e3_jax_single.json e3_jax_spmd.json e4_vs_google_linux_x64.json e5_vmem_pack.json e5_reg_spill.json e6_modulo_speedup.json e6_pass_ablations.json e7_numerics.json e7_sparsecore.json generated_metrics.tex campaign_summary.json) do (
    if not exist "!_RES!\%%R" (
        echo [FAIL] Missing libtpu-rs experiment output: %%R >&2
        exit /b 1
    )
)

findstr /C:"MetricWarmClientInitMedMs" "!_RES!\generated_metrics.tex" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] generated_metrics.tex missing MetricWarmClientInitMedMs >&2
    exit /b 1
)
findstr /C:""safe_core_zero_unsafe_verified": true" "!_RES!\e0_tcb.json" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] e0_tcb.json missing safe_core_zero_unsafe_verified: true >&2
    exit /b 1
)

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" libtpu-rs experiments --synthetic-fixtures --subsuites=E0,E1,E2,E3,E4,E5,E6,E7,E8 --warmup=2 --trials=5 "--results-dir=!_RES!" "--paper-dir=!WORK_DIR!\paper_clean" > "!WORK_DIR!\pass2.log" 2>&1
if errorlevel 1 exit /b 1

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" libtpu-rs experiments --synthetic-fixtures --force --subsuites=E0,E8 "--results-dir=!_RES!" "--paper-dir=!WORK_DIR!\paper_clean"
if errorlevel 1 exit /b 1
exit /b 0

:: ## test_tbd_placeholder_and_unsafe_gates
:: Verifies E8 rejects manuscripts with unresolved placeholders and E0 rejects unsafe blocks in libtpu-core.
:test_tbd_placeholder_and_unsafe_gates
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" libtpu-rs experiments --synthetic-fixtures --subsuites=E8 "--results-dir=!WORK_DIR!\results" "--paper-dir=!WORK_DIR!\paper_tbd" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] E8 accepted manuscript containing unresolved placeholder^^! >&2
    exit /b 1
)

set "_BAD_CORE=!WORK_DIR!\bad_unsafe_repo"
if not exist "!_BAD_CORE!\crates\libtpu-core\src" mkdir "!_BAD_CORE!\crates\libtpu-core\src"
echo pub fn bad^(^) { unsafe { core::ptr::null::^<u8^>^(^); } }> "!_BAD_CORE!\crates\libtpu-core\src\lib.rs"
pushd "!_BAD_CORE!"
git init -q
git config user.email "ci@libscript.local"
git config user.name "LibScript CI"
git add .
git commit -q -m "unsafe violation"
popd

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" libtpu-rs experiments --synthetic-fixtures --force --subsuites=E0 "--repo-dir=!_BAD_CORE!" "--results-dir=!WORK_DIR!\bad_results" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] E0 accepted unsafe block inside safe core^^! >&2
    exit /b 1
)
exit /b 0
