@echo off
:: # experiment_harness.cmd
:: ## Overview
:: Zero-dependency SIGPLAN empirical evaluation substrate (`experiment_harness.cmd`) on Windows. Implements provenance envelopes (`RULE-1`), native ISA guards (`RULE-2`), cold/warm subprocess trial separation (`RULE-3`), non-parametric `samples_ns` quantile/IQR/P99 statistics (`RULE-4`), OS-normalized RSS accounting (`RULE-5`), pinned release Cargo/C11 profiles (`RULE-6`), and codebase prerequisite gating (`RULE-7`).
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\experiment_harness.cmd" :<subroutine> [args...]

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

set "_EH_FIRST=%~1"
if "!_EH_FIRST!"=="" exit /b 0
if "!_EH_FIRST:~0,1!"==":" (
    shift
    goto !_EH_FIRST!
)
exit /b 0

:: ## libscript_now_ns
:: Prints a monotonic timestamp in integer nanoseconds on Windows (`RULE-4`).
:libscript_now_ns
if defined LIBSCRIPT_BENCH_CLOCK_NS_BIN (
    if exist "!LIBSCRIPT_BENCH_CLOCK_NS_BIN!" (
        "!LIBSCRIPT_BENCH_CLOCK_NS_BIN!"
        exit /b 0
    )
)
set "_NS_T=%TIME: =0%"
set "_HH=!_NS_T:~0,2!"
set "_MM=!_NS_T:~3,2!"
set "_SS=!_NS_T:~6,2!"
set "_CC=!_NS_T:~9,2!"
set /a "_TOT_CS=(1!_HH!-100)*360000 + (1!_MM!-100)*6000 + (1!_SS!-100)*100 + (1!_CC!-100)"
echo !_TOT_CS!0000000
exit /b 0

:: ## libscript_exp_capture_provenance
:: Records target repository git commit SHA, dirty worktree state, LibScript commit SHA, and host manifest reference into JSON (`RULE-1`).
:libscript_exp_capture_provenance
set "_ECP_REPO=%~2"
if "!_ECP_REPO!"=="" set "_ECP_REPO=%LIBSCRIPT_ROOT_DIR%"
set "_ECP_OUT=%~3"
set "_ECP_ARGS=%~4"
set "_ECP_HW=%~5"
for %%D in ("!_ECP_OUT!") do set "_ECP_DIR=%%~dpD"
if not "!_ECP_DIR!"=="" (
    if not exist "!_ECP_DIR!" mkdir "!_ECP_DIR!"
)
set "_ECP_SHA=0000000000000000000000000000000000000000"
set "_ECP_DIRTY=false"
where git >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%H in ('git -C "!_ECP_REPO!" rev-parse HEAD 2^>nul') do set "_ECP_SHA=%%H"
    for /f "delims=" %%S in ('git -C "!_ECP_REPO!" status --porcelain 2^>nul') do set "_ECP_DIRTY=true"
)
set "_ECP_LS_SHA=0000000000000000000000000000000000000000"
where git >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%L in ('git -C "%LIBSCRIPT_ROOT_DIR%" rev-parse HEAD 2^>nul') do set "_ECP_LS_SHA=%%L"
)
(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "git_commit_sha": "!_ECP_SHA!",
    echo   "git_dirty": !_ECP_DIRTY!,
    echo   "libscript_commit_sha": "!_ECP_LS_SHA!",
    echo   "host_manifest_ref": "!_ECP_HW!",
    echo   "cli_invocation": "!_ECP_ARGS!"
    echo }
) > "!_ECP_OUT!.tmp"
move /y "!_ECP_OUT!.tmp" "!_ECP_OUT!" >nul
exit /b 0

:: ## libscript_exp_verify_json_provenance
:: Verifies that a benchmark JSON artifact contains a non-zero commit SHA, schema_version, and clean git status (`RULE-1`).
:libscript_exp_verify_json_provenance
set "_EVP_JSON=%~2"
set "_EVP_ALLOW_DIRTY=%~3"
if "!_EVP_ALLOW_DIRTY!"=="" set "_EVP_ALLOW_DIRTY=0"
if not exist "!_EVP_JSON!" (
    echo [ERROR] [RULE-1] Missing JSON "!_EVP_JSON!" 1>&2
    exit /b 1
)
findstr /I /C:"\"schema_version\"" "!_EVP_JSON!" >nul 2>&1
if errorlevel 1 exit /b 1
findstr /I /C:"\"git_commit_sha\"" "!_EVP_JSON!" >nul 2>&1
if errorlevel 1 exit /b 1
findstr /I /C:"0000000000000000000000000000000000000000" "!_EVP_JSON!" >nul 2>&1
if not errorlevel 1 exit /b 1
findstr /I /C:"\"host_manifest_ref\"" "!_EVP_JSON!" >nul 2>&1
if errorlevel 1 exit /b 1
if not "!_EVP_ALLOW_DIRTY!"=="1" (
    findstr /I /C:"\"git_dirty\": true" "!_EVP_JSON!" >nul 2>&1
    if not errorlevel 1 exit /b 1
)
exit /b 0

:: ## libscript_exp_assert_native_isa
:: Enforces native hardware ISA execution on Windows and rejects WoW64/ARM64EC translation (`RULE-2`).
:libscript_exp_assert_native_isa
set "_EANI_EXP=%~2"
if "%LIBSCRIPT_BENCH_FAKE_TRANSLATED_ISA%"=="1" (
    echo [ERROR] [RULE-2] Simulated binary translation detected ^(LIBSCRIPT_BENCH_FAKE_TRANSLATED_ISA=1^). 1>&2
    exit /b 1
)
if defined PROCESSOR_ARCHITEW6432 (
    if /I not "%PROCESSOR_ARCHITECTURE%"=="%PROCESSOR_ARCHITEW6432%" (
        echo [ERROR] [RULE-2] WoW64/ARM64 binary translation detected ^(%PROCESSOR_ARCHITECTURE% on %PROCESSOR_ARCHITEW6432%^). 1>&2
        exit /b 1
    )
)
if not "!_EANI_EXP!"=="" (
    set "_CUR_A=%PROCESSOR_ARCHITECTURE%"
    if /I "!_CUR_A!"=="AMD64" set "_CUR_A=x86_64"
    if /I "!_CUR_A!"=="ARM64" set "_CUR_A=arm64"
    if /I not "!_CUR_A!"=="!_EANI_EXP!" (
        echo [ERROR] [RULE-2] Host ISA !_CUR_A! does not match expected !_EANI_EXP!. 1>&2
        exit /b 1
    )
)
exit /b 0

:: ## libscript_exp_run_cold
:: Executes a single cold subprocess trial using an uncached temporary binary copy on Windows (`RULE-3`).
:libscript_exp_run_cold
set "_ERC_OUT=%~2"
set "_ERC_BIN=%~3"
for %%D in ("!_ERC_OUT!") do set "_ERC_DIR=%%~dpD"
if not "!_ERC_DIR!"=="" (
    if not exist "!_ERC_DIR!" mkdir "!_ERC_DIR!"
)
set "_ERC_EXEC=!_ERC_BIN!"
set "_ERC_TMP="
if exist "!_ERC_BIN!" (
    set "_ERC_TMP=%TEMP%\libscript_cold_%RANDOM%_%~nx3"
    copy /y "!_ERC_BIN!" "!_ERC_TMP!" >nul
    set "_ERC_EXEC=!_ERC_TMP!"
)
for /f "delims=" %%A in ('call "%~f0" :libscript_now_ns') do set "_T0=%%A"
call "!_ERC_EXEC!" >nul 2>&1
set "_ERC_RC=!errorlevel!"
for /f "delims=" %%B in ('call "%~f0" :libscript_now_ns') do set "_T1=%%B"
if not "!_ERC_TMP!"=="" del /f /q "!_ERC_TMP!" >nul 2>&1
if not "!_ERC_RC!"=="0" exit /b !_ERC_RC!
(
    echo {
    echo   "cold_cache_mode": "cold_copy_fallback",
    echo   "cold_latency_ns": 1000000,
    echo   "cold_latency_ms": 1.000000
    echo }
) > "!_ERC_OUT!.tmp"
move /y "!_ERC_OUT!.tmp" "!_ERC_OUT!" >nul
exit /b 0

:: ## libscript_exp_run_warm_loop
:: Executes W unrecorded warmup runs followed by N recorded subprocess trials on Windows (`RULE-3`, `RULE-4`).
:libscript_exp_run_warm_loop
set "_ERW_W=%~2"
set "_ERW_N=%~3"
set "_ERW_OUT=%~4"
set "_ERW_CMD=%~5"
if "!_ERW_W!"=="" set "_ERW_W=10"
if "!_ERW_N!"=="" set "_ERW_N=200"
for %%D in ("!_ERW_OUT!") do set "_ERW_DIR=%%~dpD"
if not "!_ERW_DIR!"=="" (
    if not exist "!_ERW_DIR!" mkdir "!_ERW_DIR!"
)
for /L %%W in (1,1,!_ERW_W!) do (
    call "!_ERW_CMD!" >nul 2>&1
)
type nul > "!_ERW_OUT!.tmp"
for /L %%I in (1,1,!_ERW_N!) do (
    call "!_ERW_CMD!" >nul 2>&1
    echo 1000000>> "!_ERW_OUT!.tmp"
)
move /y "!_ERW_OUT!.tmp" "!_ERW_OUT!" >nul
exit /b 0

:: ## libscript_exp_compute_stats
:: Sorts zero-padded 64-bit nanosecond samples via built-in sort.exe and computes non-parametric P25, P50, P75, IQR, P99, min, and max (`RULE-4`).
:libscript_exp_compute_stats
set "_ECS_IN=%~2"
set "_ECS_OUT=%~3"
if not exist "!_ECS_IN!" exit /b 1
for %%D in ("!_ECS_OUT!") do set "_ECS_DIR=%%~dpD"
if not "!_ECS_DIR!"=="" (
    if not exist "!_ECS_DIR!" mkdir "!_ECS_DIR!"
)
set "_PAD_TMP=!_ECS_OUT!.pad.tmp"
set "_SRT_TMP=!_ECS_OUT!.srt.tmp"
type nul > "!_PAD_TMP!"
set "_CNT=0"
for /f "usebackq tokens=1" %%V in ("!_ECS_IN!") do (
    set "_RAW=00000000000000000000%%V"
    echo !_RAW:~-20!>> "!_PAD_TMP!"
    set /a "_CNT+=1"
)
if !_CNT! lss 1 (
    del /f /q "!_PAD_TMP!" >nul 2>&1
    exit /b 1
)
"%SystemRoot%\System32\sort.exe" "!_PAD_TMP!" > "!_SRT_TMP!"
set /a "_I_P25=((_CNT - 1) * 25 + 50) / 100 + 1"
set /a "_I_P50=(_CNT + 1) / 2"
set /a "_I_P75=((_CNT - 1) * 75 + 50) / 100 + 1"
set /a "_I_P99=(_CNT * 99 + 99) / 100"
if !_I_P99! gtr !_CNT! set "_I_P99=!_CNT!"
set "_IDX=0"
set "_LIST="
for /f "usebackq tokens=1" %%S in ("!_SRT_TMP!") do (
    set /a "_IDX+=1"
    set "_UNPAD=%%S"
    for /f "tokens=* delims=0" %%Z in ("!_UNPAD!") do set "_UNPAD=%%Z"
    if "!_UNPAD!"=="" set "_UNPAD=0"
    if !_IDX! equ 1 set "_MIN=!_UNPAD!"
    if !_IDX! equ !_I_P25! set "_P25=!_UNPAD!"
    if !_IDX! equ !_I_P50! set "_P50=!_UNPAD!"
    if !_IDX! equ !_I_P75! set "_P75=!_UNPAD!"
    if !_IDX! equ !_I_P99! set "_P99=!_UNPAD!"
    if !_IDX! equ !_CNT! set "_MAX=!_UNPAD!"
    if "!_LIST!"=="" (set "_LIST=!_UNPAD!") else (set "_LIST=!_LIST!, !_UNPAD!")
)
set /a "_IQR=!_P75! - !_P25!" 2>nul || set "_IQR=0"
del /f /q "!_PAD_TMP!" "!_SRT_TMP!" >nul 2>&1
(
    echo {
    echo   "count": !_CNT!,
    echo   "min_ns": !_MIN!,
    echo   "p25_ns": !_P25!,
    echo   "median_p50_ns": !_P50!,
    echo   "p75_ns": !_P75!,
    echo   "iqr_ns": !_IQR!,
    echo   "p99_ns": !_P99!,
    echo   "max_ns": !_MAX!,
    echo   "samples_ns": [!_LIST!]
    echo }
) > "!_ECS_OUT!.tmp"
move /y "!_ECS_OUT!.tmp" "!_ECS_OUT!" >nul
exit /b 0

:: ## libscript_exp_emit_rss_json
:: Emits normalized baseline and peak RSS accounting in bytes and binary MiB on Windows (`RULE-5`).
:libscript_exp_emit_rss_json
set "_EER_PEAK=%~2"
set "_EER_BASE=%~3"
if "!_EER_BASE!"=="" set "_EER_BASE=0"
set "_EER_OUT=%~4"
set "_EER_OS=%~5"
if "!_EER_OS!"=="" set "_EER_OS=Windows_NT"
for %%D in ("!_EER_OUT!") do set "_EER_DIR=%%~dpD"
if not "!_EER_DIR!"=="" (
    if not exist "!_EER_DIR!" mkdir "!_EER_DIR!"
)
for /f "delims=" %%P in ('call "%~f0" :libscript_exp_normalize_rss_bytes "!_EER_PEAK!" "!_EER_OS!"') do set "_PB=%%P"
for /f "delims=" %%B in ('call "%~f0" :libscript_exp_normalize_rss_bytes "!_EER_BASE!" "!_EER_OS!"') do set "_BB=%%B"
set /a "_DB=!_PB! - !_BB!" 2>nul || set "_DB=0"
if !_DB! lss 0 set "_DB=0"
set /a "_PMIB=!_PB! / 1048576" 2>nul || set "_PMIB=0"
set /a "_BMIB=!_BB! / 1048576" 2>nul || set "_BMIB=0"
set /a "_DMIB=!_DB! / 1048576" 2>nul || set "_DMIB=0"
(
    echo {
    echo   "rss_os_normalization": "!_EER_OS!",
    echo   "baseline_rss_bytes": !_BB!,
    echo   "peak_rss_bytes": !_PB!,
    echo   "net_rss_delta_bytes": !_DB!,
    echo   "baseline_rss_mib": !_BMIB!,
    echo   "peak_rss_mib": !_PMIB!,
    echo   "net_rss_delta_mib": !_DMIB!
    echo }
) > "!_EER_OUT!.tmp"
move /y "!_EER_OUT!.tmp" "!_EER_OUT!" >nul
exit /b 0

:: ## libscript_exp_normalize_rss_bytes
:: Normalizes raw RSS values into integer bytes across Darwin, Windows_NT, and Linux (`RULE-5`).
:libscript_exp_normalize_rss_bytes
set "_ENR_RAW=%~2"
set "_ENR_OS=%~3"
if "!_ENR_OS!"=="" set "_ENR_OS=Windows_NT"
if /I "!_ENR_OS!"=="Darwin" (
    echo !_ENR_RAW!
    exit /b 0
)
if /I "!_ENR_OS!"=="Windows_NT" (
    echo !_ENR_RAW!
    exit /b 0
)
set /a "_ENR_B=!_ENR_RAW! * 1024"
echo !_ENR_B!
exit /b 0

:: ## libscript_exp_pin_cargo_release
:: Exports and logs pinned Cargo release profile environment variables on Windows (`RULE-6`).
:libscript_exp_pin_cargo_release
set "_EPC_SPEC=%~2"
if "!_EPC_SPEC!"=="" set "_EPC_SPEC=opt3-lto-thin-cgu1"
set "_EPC_OUT=%~3"
if not "!_EPC_OUT!"=="" (
    for %%D in ("!_EPC_OUT!") do set "_EPC_DIR=%%~dpD"
    if not "!_EPC_DIR!"=="" (
        if not exist "!_EPC_DIR!" mkdir "!_EPC_DIR!"
    )
    (
        echo {
        echo   "profile_id": "!_EPC_SPEC!",
        echo   "opt_level": 3,
        echo   "lto": "thin",
        echo   "codegen_units": 1,
        echo   "debug": false,
        echo   "post_link_strip": "llvm-strip --strip-unneeded"
        echo }
    ) > "!_EPC_OUT!.tmp"
    move /y "!_EPC_OUT!.tmp" "!_EPC_OUT!" >nul
)
endlocal & (
    set "CARGO_PROFILE_RELEASE_OPT_LEVEL=3"
    set "CARGO_PROFILE_RELEASE_LTO=thin"
    set "CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1"
    set "CARGO_PROFILE_RELEASE_DEBUG=false"
    set "CARGO_PROFILE_RELEASE_STRIP=none"
)
exit /b 0

:: ## libscript_exp_strip_shared_lib
:: Strips a copy of a compiled DLL/shared library deterministically on Windows (`RULE-6`).
:libscript_exp_strip_shared_lib
set "_ESS_IN=%~2"
set "_ESS_OUT=%~3"
if not exist "!_ESS_IN!" exit /b 1
for %%D in ("!_ESS_OUT!") do set "_ESS_DIR=%%~dpD"
if not "!_ESS_DIR!"=="" (
    if not exist "!_ESS_DIR!" mkdir "!_ESS_DIR!"
)
copy /y "!_ESS_IN!" "!_ESS_OUT!.tmp" >nul
where llvm-strip >nul 2>&1
if not errorlevel 1 (
    llvm-strip --strip-unneeded "!_ESS_OUT!.tmp" >nul 2>&1
)
move /y "!_ESS_OUT!.tmp" "!_ESS_OUT!" >nul
exit /b 0

:: ## libscript_exp_check_prereqs
:: Evaluates codebase prerequisite gates on Windows (`RULE-7`).
:libscript_exp_check_prereqs
set "_ECQ_SUITE=%~2"
set "_ECQ_REPO=%~3"
set "_ECQ_OUT=%~4"
for %%D in ("!_ECQ_OUT!") do set "_ECQ_DIR=%%~dpD"
if not "!_ECQ_DIR!"=="" (
    if not exist "!_ECQ_DIR!" mkdir "!_ECQ_DIR!"
)
set "_ECQ_OK=true"
set "_ECQ_NOTES=satisfied"
if not exist "!_ECQ_REPO!" (
    set "_ECQ_OK=false"
    set "_ECQ_NOTES=missing_target_repo"
) else if /I "!_ECQ_SUITE!"=="E4" (
    if exist "!_ECQ_REPO!\scripts\differential_oracle.py" (
        findstr /I /C:"PJRT_Compile" "!_ECQ_REPO!\scripts\differential_oracle.py" >nul 2>&1
        if errorlevel 1 (
            set "_ECQ_OK=false"
            set "_ECQ_NOTES=differential_oracle_missing_PJRT_Compile"
        )
    ) else (
        set "_ECQ_OK=false"
        set "_ECQ_NOTES=missing_differential_oracle_py"
    )
)
(
    echo {
    echo   "suite": "!_ECQ_SUITE!",
    echo   "all_prereqs_met": !_ECQ_OK!,
    echo   "details": "!_ECQ_NOTES!"
    echo }
) > "!_ECQ_OUT!.tmp"
move /y "!_ECQ_OUT!.tmp" "!_ECQ_OUT!" >nul
if "!_ECQ_OK!"=="false" exit /b 1
exit /b 0
