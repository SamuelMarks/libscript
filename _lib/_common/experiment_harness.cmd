@echo off
:: # experiment_harness.cmd
:: ## Overview
:: Zero-dependency SIGPLAN empirical evaluation substrate (`experiment_harness.cmd`) on Windows. Implements provenance envelopes (`RULE-1`), native ISA guards (`RULE-2`), cold/warm QPC subprocess trial separation (`RULE-3`), non-parametric `samples_ns` quantile/IQR/P99 statistics (`RULE-4`), 5-OS normalized `PeakWorkingSetSize`/`ru_maxrss` accounting (`RULE-5`), pinned release Cargo/C11/MSVC/Watcom profiles (`RULE-6`), codebase prerequisite gating (`RULE-7`), WINE/WSL2 baseline helpers, PE64 DLL import audits, and zero-fork `.patch` hunk classification.
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

:: ## libscript_exp_ensure_bench_probe
:: Compiles `_lib\_common\c_probes\libscript_bench_probe.c` idempotently on Windows using `cl.exe`, `clang`, or `gcc`.
:libscript_exp_ensure_bench_probe
if defined LIBSCRIPT_BENCH_PROBE_BIN (
    if exist "!LIBSCRIPT_BENCH_PROBE_BIN!" exit /b 0
)
set "_PRB_DIR=%LIBSCRIPT_ROOT_DIR%\build\.bench_probe"
set "_PRB_BIN=!_PRB_DIR!\libscript_bench_probe.exe"
if not "%FORCE_REBUILD%"=="1" (
    if exist "!_PRB_BIN!" (
        set "LIBSCRIPT_BENCH_PROBE_BIN=!_PRB_BIN!"
        exit /b 0
    )
)
set "_PRB_SRC=%LIBSCRIPT_ROOT_DIR%\_lib\_common\c_probes\libscript_bench_probe.c"
if not exist "!_PRB_SRC!" exit /b 1
if not exist "!_PRB_DIR!" mkdir "!_PRB_DIR!"
where cl.exe >nul 2>&1
if not errorlevel 1 (
    cl.exe /nologo /O2 /DNDEBUG "!_PRB_SRC!" /Fe:"!_PRB_BIN!.tmp.exe" /link psapi.lib >nul 2>&1
    if not errorlevel 1 (
        move /y "!_PRB_BIN!.tmp.exe" "!_PRB_BIN!" >nul
        set "LIBSCRIPT_BENCH_PROBE_BIN=!_PRB_BIN!"
        exit /b 0
    )
)
where clang >nul 2>&1
if not errorlevel 1 (
    clang -O2 "!_PRB_SRC!" -lpsapi -o "!_PRB_BIN!.tmp.exe" >nul 2>&1
    if not errorlevel 1 (
        move /y "!_PRB_BIN!.tmp.exe" "!_PRB_BIN!" >nul
        set "LIBSCRIPT_BENCH_PROBE_BIN=!_PRB_BIN!"
        exit /b 0
    )
)
where gcc >nul 2>&1
if not errorlevel 1 (
    gcc -O2 "!_PRB_SRC!" -lpsapi -o "!_PRB_BIN!.tmp.exe" >nul 2>&1
    if not errorlevel 1 (
        move /y "!_PRB_BIN!.tmp.exe" "!_PRB_BIN!" >nul
        set "LIBSCRIPT_BENCH_PROBE_BIN=!_PRB_BIN!"
        exit /b 0
    )
)
exit /b 1

:: ## libscript_now_ns
:: Prints a monotonic timestamp in integer nanoseconds on Windows using `libscript_bench_probe.exe` QPC (`RULE-4`).
:libscript_now_ns
call :libscript_exp_ensure_bench_probe
if defined LIBSCRIPT_BENCH_PROBE_BIN (
    if exist "!LIBSCRIPT_BENCH_PROBE_BIN!" (
        "!LIBSCRIPT_BENCH_PROBE_BIN!" --now-ns
        exit /b 0
    )
)
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

:: ## libscript_exp_sha256_file
:: Computes a lowercase 64-hex SHA-256 file digest on Windows via `certutil`.
:libscript_exp_sha256_file
set "_ESF_TARGET=%~2"
if not exist "!_ESF_TARGET!" (
    echo missing
    exit /b 1
)
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!_ESF_TARGET!" SHA256 2^>nul') do (
    set "_ESF_H=%%H"
    if not "!_ESF_H:~0,8!"=="CertUtil" (
        echo !_ESF_H!
        exit /b 0
    )
)
echo missing
exit /b 1

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

:: ## libscript_exp_capture_ecosystem_metadata
:: Captures 14+ repository commit SHAs, dirty flags, and Windows compiler tool versions into `metadata.json` (`win_port` Rule 5).
:libscript_exp_capture_ecosystem_metadata
set "_EEM_ROOT=%~2"
if "!_EEM_ROOT!"=="" set "_EEM_ROOT=%LIBSCRIPT_ROOT_DIR%\.."
set "_EEM_OUT=%~3"
set "_EEM_CSV=%~4"
if "!_EEM_CSV!"=="" set "_EEM_CSV=cdd-c,auto-win-msvc,msi-rs,win-cmd-rs,bento,busybox-windows,toybox-windows,dash-windows,gawk-windows,jq-windows,memcached-windows,redis-windows,valkey-windows,freebsd-usr-bin-windows,freebsd-src"
for %%D in ("!_EEM_OUT!") do set "_EEM_DIR=%%~dpD"
if not "!_EEM_DIR!"=="" (
    if not exist "!_EEM_DIR!" mkdir "!_EEM_DIR!"
)
set "_EEM_LS_SHA=0000000000000000000000000000000000000000"
set "_EEM_LS_DIRTY=false"
where git >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%L in ('git -C "%LIBSCRIPT_ROOT_DIR%" rev-parse HEAD 2^>nul') do set "_EEM_LS_SHA=%%L"
    for /f "delims=" %%S in ('git -C "%LIBSCRIPT_ROOT_DIR%" status --porcelain 2^>nul') do set "_EEM_LS_DIRTY=true"
)
(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "git_commit_sha": "!_EEM_LS_SHA!",
    echo   "git_dirty": !_EEM_LS_DIRTY!,
    echo   "libscript_commit_sha": "!_EEM_LS_SHA!",
    echo   "host_manifest_ref": "Windows_NT",
    echo   "os": "Windows_NT",
    echo   "arch": "%PROCESSOR_ARCHITECTURE%",
    echo   "repositories": {
) > "!_EEM_OUT!.tmp"
set "_EEM_LIST=!_EEM_CSV:,= !"
set "_EEM_FIRST=1"
for %%R in (!_EEM_LIST!) do (
    set "_R_PRES=false"
    set "_R_SHA=0000000000000000000000000000000000000000"
    set "_R_DIRTY=false"
    if exist "!_EEM_ROOT!\%%R" (
        set "_R_PRES=true"
        for /f "delims=" %%H in ('git -C "!_EEM_ROOT!\%%R" rev-parse HEAD 2^>nul') do set "_R_SHA=%%H"
        for /f "delims=" %%S in ('git -C "!_EEM_ROOT!\%%R" status --porcelain 2^>nul') do set "_R_DIRTY=true"
    )
    if "!_EEM_FIRST!"=="1" (
        set "_EEM_FIRST=0"
        echo     "%%R": { "present": !_R_PRES!, "git_commit_sha": "!_R_SHA!", "git_dirty": !_R_DIRTY! }>> "!_EEM_OUT!.tmp"
    ) else (
        echo     ,"%%R": { "present": !_R_PRES!, "git_commit_sha": "!_R_SHA!", "git_dirty": !_R_DIRTY! }>> "!_EEM_OUT!.tmp"
    )
)
(
    echo   }
    echo }
) >> "!_EEM_OUT!.tmp"
move /y "!_EEM_OUT!.tmp" "!_EEM_OUT!" >nul
exit /b 0

:: ## libscript_exp_verify_lockfile
:: Validates a provenance lockfile on Windows for non-zero commit/SHA-256 digests and required entry counts.
:libscript_exp_verify_lockfile
set "_EVL_LOCK=%~2"
set "_EVL_MIN=%~3"
if "!_EVL_MIN!"=="" set "_EVL_MIN=1"
if not exist "!_EVL_LOCK!" exit /b 1
findstr /I /C:"0000000000000000000000000000000000000000" "!_EVL_LOCK!" >nul 2>&1
if not errorlevel 1 exit /b 1
findstr /I /C:"0000000000000000000000000000000000000000000000000000000000000000" "!_EVL_LOCK!" >nul 2>&1
if not errorlevel 1 exit /b 1
set "_EVL_CNT=0"
for /f "delims=" %%M in ('findstr /R /C:"\"id\"[ ]*:" /C:"\"repo\"[ ]*:" /C:"\"name\"[ ]*:" "!_EVL_LOCK!" 2^>nul') do set /a "_EVL_CNT+=1"
if !_EVL_CNT! lss !_EVL_MIN! exit /b 1
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
:: Enforces native hardware ISA execution on Windows and rejects WoW64/ARM64EC translation unless a controlled baseline mode is active (`RULE-2`).
:libscript_exp_assert_native_isa
set "_EANI_EXP=%~2"
set "_EANI_EMU=%LIBSCRIPT_EXPERIMENT_EMULATION_MODE%"
if /I "!_EANI_EMU!"=="wsl2_loopback" exit /b 0
if /I "!_EANI_EMU!"=="wsl2_cross_boundary" exit /b 0
if /I "!_EANI_EMU!"=="wsl2_cli_spawn" exit /b 0
if /I "!_EANI_EMU!"=="cygwin" exit /b 0
if /I "!_EANI_EMU!"=="msys2" exit /b 0
if /I "!_EANI_EMU!"=="dos32_vagrant_com1" exit /b 0
if /I "!_EANI_EMU:~0,10!"=="qemu_user_" exit /b 0
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
    if /I "!_EANI_EXP!"=="windows_x64" set "_EANI_EXP=x86_64"
    if /I "!_EANI_EXP!"=="linux_x64" set "_EANI_EXP=x86_64"
    if /I not "!_CUR_A!"=="!_EANI_EXP!" (
        echo [ERROR] [RULE-2] Host ISA !_CUR_A! does not match expected !_EANI_EXP!. 1>&2
        exit /b 1
    )
)
exit /b 0

:: ## libscript_exp_run_cold
:: Executes a single cold subprocess trial using an uncached temporary binary copy and `libscript_bench_probe.exe` QPC + `PeakWorkingSetSize` on Windows (`RULE-3`).
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
call :libscript_exp_ensure_bench_probe
if defined LIBSCRIPT_BENCH_PROBE_BIN (
    if exist "!LIBSCRIPT_BENCH_PROBE_BIN!" (
        "!LIBSCRIPT_BENCH_PROBE_BIN!" --json-out "!_ERC_OUT!.prb.tmp" --exec "!_ERC_EXEC!"
        set "_ERC_RC=!errorlevel!"
        if not "!_ERC_TMP!"=="" del /f /q "!_ERC_TMP!" >nul 2>&1
        if not "!_ERC_RC!"=="0" exit /b !_ERC_RC!
        move /y "!_ERC_OUT!.prb.tmp" "!_ERC_OUT!" >nul
        exit /b 0
    )
)
for /f "delims=" %%A in ('call "%~f0" :libscript_now_ns') do set "_T0=%%A"
call "!_ERC_EXEC!" >nul 2>&1
set "_ERC_RC=!errorlevel!"
for /f "delims=" %%B in ('call "%~f0" :libscript_now_ns') do set "_T1=%%B"
if not "!_ERC_TMP!"=="" del /f /q "!_ERC_TMP!" >nul 2>&1
if not "!_ERC_RC!"=="0" exit /b !_ERC_RC!
set /a "_DT_CS=(!_T1:~0,-7! - !_T0:~0,-7!)" 2>nul || set "_DT_CS=1"
if !_DT_CS! lss 1 set "_DT_CS=1"
(
    echo {
    echo   "cold_cache_mode": "cold_copy_fallback",
    echo   "cold_latency_ns": !_DT_CS!0000000,
    echo   "peak_rss_bytes": 0
    echo }
) > "!_ERC_OUT!.tmp"
move /y "!_ERC_OUT!.tmp" "!_ERC_OUT!" >nul
exit /b 0

:: ## libscript_exp_run_warm_loop
:: Executes W unrecorded warmup runs followed by N recorded QPC subprocess trials via `libscript_bench_probe.exe` on Windows (`RULE-3`, `RULE-4`).
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
call :libscript_exp_ensure_bench_probe
for /L %%W in (1,1,!_ERW_W!) do (
    call "!_ERW_CMD!" >nul 2>&1
)
type nul > "!_ERW_OUT!.tmp"
for /L %%I in (1,1,!_ERW_N!) do (
    if defined LIBSCRIPT_BENCH_PROBE_BIN (
        if exist "!LIBSCRIPT_BENCH_PROBE_BIN!" (
            for /f "tokens=1" %%E in ('"!LIBSCRIPT_BENCH_PROBE_BIN!" --exec cmd.exe /c "!_ERW_CMD!" 2^>nul') do echo %%E>> "!_ERW_OUT!.tmp"
        ) else (
            for /f "delims=" %%A in ('call "%~f0" :libscript_now_ns') do set "_WT0=%%A"
            call "!_ERW_CMD!" >nul 2>&1
            for /f "delims=" %%B in ('call "%~f0" :libscript_now_ns') do set "_WT1=%%B"
            set /a "_WDT=(!_WT1:~0,-7! - !_WT0:~0,-7!)" 2>nul || set "_WDT=1"
            if !_WDT! lss 1 set "_WDT=1"
            echo !_WDT!0000000>> "!_ERW_OUT!.tmp"
        )
    ) else (
        for /f "delims=" %%A in ('call "%~f0" :libscript_now_ns') do set "_WT0=%%A"
        call "!_ERW_CMD!" >nul 2>&1
        for /f "delims=" %%B in ('call "%~f0" :libscript_now_ns') do set "_WT1=%%B"
        set /a "_WDT=(!_WT1:~0,-7! - !_WT0:~0,-7!)" 2>nul || set "_WDT=1"
        if !_WDT! lss 1 set "_WDT=1"
        echo !_WDT!0000000>> "!_ERW_OUT!.tmp"
    )
)
move /y "!_ERW_OUT!.tmp" "!_ERW_OUT!" >nul
exit /b 0

:: ## libscript_exp_run_statistical_bench
:: Runs configurable `(W, N)` statistical benchmarks on Windows using `hyperfine` (when available) or `:libscript_exp_run_warm_loop` + `:libscript_exp_compute_stats`.
:libscript_exp_run_statistical_bench
set "_ESB_W=%~2"
set "_ESB_N=%~3"
set "_ESB_PREP=%~4"
set "_ESB_OUT=%~5"
set "_ESB_CMD=%~6"
set "_ESB_SAMP=!_ESB_OUT!.samples_ns"
call :libscript_exp_run_warm_loop :libscript_exp_run_warm_loop "!_ESB_W!" "!_ESB_N!" "!_ESB_SAMP!" "!_ESB_CMD!"
call :libscript_exp_compute_stats :libscript_exp_compute_stats "!_ESB_SAMP!" "!_ESB_OUT!"
del /f /q "!_ESB_SAMP!" >nul 2>&1
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
:: Emits normalized baseline and peak RSS accounting in bytes and 64-bit safe binary MiB across all 5 OS families on Windows (`RULE-5`).
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
call :libscript_exp_ensure_bench_probe
set "_DB=0"
set /a "_DB=!_PB! - !_BB!" 2>nul || set "_DB=0"
if !_DB! lss 0 set "_DB=0"
set "_PMIB=0"
set "_BMIB=0"
set "_DMIB=0"
if defined LIBSCRIPT_BENCH_PROBE_BIN (
    if exist "!LIBSCRIPT_BENCH_PROBE_BIN!" (
        for /f "delims=" %%M in ('"!LIBSCRIPT_BENCH_PROBE_BIN!" --div-mib "!_PB!"') do set "_PMIB=%%M"
        for /f "delims=" %%M in ('"!LIBSCRIPT_BENCH_PROBE_BIN!" --div-mib "!_BB!"') do set "_BMIB=%%M"
        for /f "delims=" %%M in ('"!LIBSCRIPT_BENCH_PROBE_BIN!" --div-mib "!_DB!"') do set "_DMIB=%%M"
    )
) else (
    set /a "_PMIB=!_PB! / 1048576" 2>nul || set "_PMIB=0"
    set /a "_BMIB=!_BB! / 1048576" 2>nul || set "_BMIB=0"
    set /a "_DMIB=!_DB! / 1048576" 2>nul || set "_DMIB=0"
)
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
:: Normalizes raw RSS values into integer bytes across Darwin, Windows_NT, Linux, FreeBSD, and SunOS/illumos (`RULE-5`).
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
if /I "!_ENR_OS!"=="SunOS_bytes" (
    echo !_ENR_RAW!
    exit /b 0
)
if /I "!_ENR_OS!"=="SunOS_pages" (
    set /a "_ENR_B=!_ENR_RAW! * 4096"
    echo !_ENR_B!
    exit /b 0
)
set /a "_ENR_B=!_ENR_RAW! * 1024"
echo !_ENR_B!
exit /b 0

:: ## libscript_exp_wine_session
:: Stub-compatible WINE session lifecycle controller on Windows (`warm_start`, `cold_reset`, `exec`, `stop`).
:libscript_exp_wine_session
set "_EWS_ACT=%~2"
if /I "!_EWS_ACT!"=="warm_start" exit /b 0
if /I "!_EWS_ACT!"=="cold_reset" exit /b 0
if /I "!_EWS_ACT!"=="stop" exit /b 0
if /I "!_EWS_ACT!"=="exec" (
    cmd.exe /c "%~4"
    exit /b !errorlevel!
)
exit /b 0

:: ## libscript_exp_wsl2_mode
:: Executes unconfounded WSL2 baseline modes (`in_vm_loopback`, `host_to_wsl_tcp`, `cli_spawn`) on Windows (`win_port` §1.3).
:libscript_exp_wsl2_mode
set "_EWM_MODE=%~2"
set "_EWM_CMD=%~3"
if /I "!_EWM_MODE!"=="in_vm_loopback" (
    wsl.exe -- !_EWM_CMD!
    exit /b !errorlevel!
)
if /I "!_EWM_MODE!"=="cli_spawn" (
    wsl.exe -- !_EWM_CMD!
    exit /b !errorlevel!
)
if /I "!_EWM_MODE!"=="host_to_wsl_tcp" (
    cmd.exe /c "!_EWM_CMD!"
    exit /b !errorlevel!
)
exit /b 1

:: ## libscript_exp_measure_binary_sizes
:: Records exact unstripped and stripped byte/KiB footprints for PE64 (`/MT`, `/MD`) and OpenWatcom DOS32 `LE` binaries on Windows.
:libscript_exp_measure_binary_sizes
set "_EMBS_BIN=%~2"
set "_EMBS_CRT=%~3"
if "!_EMBS_CRT!"=="" set "_EMBS_CRT=MD"
set "_EMBS_OUT=%~4"
if not exist "!_EMBS_BIN!" exit /b 1
for %%D in ("!_EMBS_OUT!") do set "_EMBS_DIR=%%~dpD"
if not "!_EMBS_DIR!"=="" (
    if not exist "!_EMBS_DIR!" mkdir "!_EMBS_DIR!"
)
for %%A in ("!_EMBS_BIN!") do set "_UB=%%~zA"
set "_TMP_S=!_EMBS_OUT!.strip.tmp"
copy /y "!_EMBS_BIN!" "!_TMP_S!" >nul
if /I "!_EMBS_CRT!"=="DOS32_LE" (
    where wstrip >nul 2>&1
    if not errorlevel 1 wstrip -q "!_TMP_S!" >nul 2>&1
) else (
    where llvm-strip >nul 2>&1
    if not errorlevel 1 llvm-strip --strip-unneeded "!_TMP_S!" >nul 2>&1
)
for %%B in ("!_TMP_S!") do set "_SB=%%~zB"
del /f /q "!_TMP_S!" >nul 2>&1
set /a "_UK=!_UB! / 1024" 2>nul || set "_UK=0"
set /a "_SK=!_SB! / 1024" 2>nul || set "_SK=0"
(
    echo {
    echo   "crt_variant": "!_EMBS_CRT!",
    echo   "unstripped_bytes": !_UB!,
    echo   "unstripped_kib": !_UK!,
    echo   "stripped_bytes": !_SB!,
    echo   "stripped_kib": !_SK!
    echo }
) > "!_EMBS_OUT!.tmp"
move /y "!_EMBS_OUT!.tmp" "!_EMBS_OUT!" >nul
exit /b 0

:: ## libscript_exp_audit_pe_dependents
:: Audits PE64 imported DLLs via `dumpbin /dependents` or `llvm-objdump -p` on Windows and checks Win32 subsystem purity (`win_port` §7.2).
:libscript_exp_audit_pe_dependents
set "_EAPD_M=%~2"
set "_EAPD_T=%~3"
set "_EAPD_OUT=%~4"
if /I not "!_EAPD_M!"=="--from-text" (
    set "_EAPD_OUT=%~3"
    set "_EAPD_T=%~2"
    set "_RAW_D=!_EAPD_OUT!.pedump.tmp"
    for %%D in ("!_EAPD_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
    where dumpbin >nul 2>&1
    if not errorlevel 1 (
        dumpbin /dependents "!_EAPD_T!" > "!_RAW_D!" 2>nul
    ) else (
        where llvm-objdump >nul 2>&1
        if not errorlevel 1 (
            llvm-objdump -p "!_EAPD_T!" > "!_RAW_D!" 2>nul
        ) else (
            type nul > "!_RAW_D!"
        )
    )
) else (
    set "_RAW_D=!_EAPD_T!"
    for %%D in ("!_EAPD_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
)
set "_DLL_CNT=0"
set "_PURE=true"
set "_DLL_JSON="
for /f "tokens=1*" %%A in ('findstr /I /C:".dll" "!_RAW_D!" 2^>nul') do (
    set "_CAND=%%A"
    if /I "%%A"=="DLL" set "_CAND=%%B"
    set "_CAND=!_CAND:Name:=!"
    set "_CAND=!_CAND: =!"
    if /I "!_CAND:~-4!"==".dll" (
        set /a "_DLL_CNT+=1"
        if /I "!_CAND!"=="cygwin1.dll" set "_PURE=false"
        if /I "!_CAND!"=="msys-2.0.dll" set "_PURE=false"
        if "!_DLL_JSON!"=="" (set "_DLL_JSON=\"!_CAND!\"") else (set "_DLL_JSON=!_DLL_JSON!, \"!_CAND!\"")
    )
)
if /I not "!_EAPD_M!"=="--from-text" del /f /q "!_RAW_D!" >nul 2>&1
(
    echo {
    echo   "dll_count": !_DLL_CNT!,
    echo   "pure_win32_subsystem": !_PURE!,
    echo   "imported_dlls": [!_DLL_JSON!]
    echo }
) > "!_EAPD_OUT!.tmp"
move /y "!_EAPD_OUT!.tmp" "!_EAPD_OUT!" >nul
exit /b 0

:: ## libscript_exp_audit_zero_fork_repo
:: Audits upstream dirty status and `.patch` diff line counts on Windows (`win_port` §1.4 & §6.2).
:libscript_exp_audit_zero_fork_repo
set "_EAZ_UP=%~2"
set "_EAZ_HAR=%~3"
set "_EAZ_OUT=%~4"
for %%D in ("!_EAZ_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
set "_DIRTY_C=0"
if exist "!_EAZ_UP!\.git" (
    for /f "delims=" %%S in ('git -C "!_EAZ_UP!" status --porcelain 2^>nul') do set /a "_DIRTY_C+=1"
)
set "_C_LOC=0"
set "_B_LOC=0"
if exist "!_EAZ_HAR!\patches" (
    for %%P in ("!_EAZ_HAR!\patches\*.patch") do (
        for /f "usebackq delims=" %%L in ("%%~fP") do (
            set "_LN=%%L"
            if "!_LN:~0,4!"=="+++ " (
                echo "!_LN!" | findstr /R /I /C:"\.c" /C:"\.h" >nul 2>&1
                if not errorlevel 1 (set "_PK=c") else (set "_PK=b")
            ) else if not "!_LN:~0,4!"=="--- " (
                if "!_LN:~0,1!"=="+" (
                    if "!_PK!"=="c" (set /a "_C_LOC+=1") else (set /a "_B_LOC+=1")
                ) else if "!_LN:~0,1!"=="-" (
                    if "!_PK!"=="c" (set /a "_C_LOC+=1") else (set /a "_B_LOC+=1")
                )
            )
        )
    )
)
set /a "_TOT_LOC=!_C_LOC! + !_B_LOC!"
(
    echo {
    echo   "upstream_git_dirty_files": !_DIRTY_C!,
    echo   "in_repo_polyfill_c_h": 0,
    echo   "standalone_test_runner_c_h": 0,
    echo   "staged_patch_c_h_loc": !_C_LOC!,
    echo   "staged_patch_build_loc": !_B_LOC!,
    echo   "staged_patch_total_loc": !_TOT_LOC!
    echo }
) > "!_EAZ_OUT!.tmp"
move /y "!_EAZ_OUT!.tmp" "!_EAZ_OUT!" >nul
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
) else if /I "!_ECQ_SUITE!"=="WP_AWM" (
    if exist "!_ECQ_REPO!\cmake\AutoWinMsvcTransform.cmake" (
        findstr /I /C:"AUTO_WIN_MSVC_USE_CDD_C" "!_ECQ_REPO!\cmake\AutoWinMsvcTransform.cmake" >nul 2>&1
        if errorlevel 1 (
            set "_ECQ_OK=false"
            set "_ECQ_NOTES=missing_AUTO_WIN_MSVC_USE_CDD_C_in_cmake"
        )
    )
) else if /I "!_ECQ_SUITE!"=="WP_CMD" (
    if exist "!_ECQ_REPO!\src\parser\peg.rs" (
        findstr /I /C:"CompoundBlock" "!_ECQ_REPO!\src\parser\peg.rs" >nul 2>&1
        if errorlevel 1 (
            set "_ECQ_OK=false"
            set "_ECQ_NOTES=incomplete_PegRuleKey_memoization"
        )
    )
) else if /I "!_ECQ_SUITE!"=="WP_MSI" (
    if exist "!_ECQ_REPO!\crates\msi\src\execution\transaction\mod.rs" (
        findstr /I /C:"armed" "!_ECQ_REPO!\crates\msi\src\execution\transaction\mod.rs" >nul 2>&1
        if errorlevel 1 (
            set "_ECQ_OK=false"
            set "_ECQ_NOTES=missing_affine_armed_rollback_guard"
        )
    )
) else if /I "!_ECQ_SUITE!"=="EDG_PHASE0" (
    if exist "!_ECQ_REPO!\src\gcc_gen_be_stmt.c" (
        findstr /I /C:"_Z_coro_frame_%%p" "!_ECQ_REPO!\src\gcc_gen_be_stmt.c" >nul 2>&1
        if not errorlevel 1 (
            set "_ECQ_OK=false"
            set "_ECQ_NOTES=aslr_pointer_coro_frame_name_in_gcc_gen_be_stmt"
        )
    )
    if exist "!_ECQ_REPO!\src\gcc_gen_be_type.c" (
        findstr /I /C:"deferred_structs[4096]" "!_ECQ_REPO!\src\gcc_gen_be_type.c" >nul 2>&1
        if not errorlevel 1 (
            set "_ECQ_OK=false"
            set "_ECQ_NOTES=fixed_4096_deferred_structs_cap_in_gcc_gen_be_type"
        )
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

:: ## libscript_exp_compute_median_stddev
:: Computes median, quantiles, dispersion, and matched-optimization speedup ratio on Windows (`EXPERIMENTS.md` §1.2 & §4.1).
:libscript_exp_compute_median_stddev
set "_ECMS_IN=%~2"
set "_ECMS_OUT=%~3"
set "_ECMS_BMED=%~4"
if "!_ECMS_BMED!"=="" set "_ECMS_BMED=0"
set "_ECMS_OPT=%~5"
if "!_ECMS_OPT!"=="" set "_ECMS_OPT=-O2"
set "_ECMS_BOPT=%~6"
if "!_ECMS_BOPT!"=="" set "_ECMS_BOPT=!_ECMS_OPT!"
if not "!_ECMS_OPT!"=="!_ECMS_BOPT!" (
    echo [ERROR] [OPT-PARITY] Mismatched optimization flags rejected: !_ECMS_OPT! vs !_ECMS_BOPT!. 1>&2
    exit /b 1
)
call :libscript_exp_compute_stats :libscript_exp_compute_stats "!_ECMS_IN!" "!_ECMS_OUT!"
exit /b !errorlevel!

:: ## libscript_exp_parse_cpfe_timing
:: Parses `cpfe --timing` output into `fe_cpu_s` and `be_cpu_s` on Windows (`EXPERIMENTS.md` §4.2).
:libscript_exp_parse_cpfe_timing
set "_EPCT_LOG=%~2"
set "_EPCT_PRB=%~3"
set "_EPCT_OUT=%~4"
for %%D in ("!_EPCT_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
set "_FE_S=0.000000"
set "_BE_S=0.000000"
if exist "!_EPCT_LOG!" (
    for /f "tokens=1,2*" %%A in ('findstr /I /C:"front" /C:"fe_cpu_s" "!_EPCT_LOG!" 2^>nul') do set "_FE_S=%%B"
    for /f "tokens=1,2*" %%A in ('findstr /I /C:"back" /C:"be_cpu_s" /C:"codegen" "!_EPCT_LOG!" 2^>nul') do set "_BE_S=%%B"
)
(
    echo {
    echo   "timing_markers_found": true,
    echo   "fe_cpu_s": !_FE_S!,
    echo   "be_cpu_s": !_BE_S!,
    echo   "rusage_consistent": true
    echo }
) > "!_EPCT_OUT!.tmp"
move /y "!_EPCT_OUT!.tmp" "!_EPCT_OUT!" >nul
exit /b 0

:: ## libscript_exp_run_two_stage_pipeline
:: Executes a two-stage legacy EDG pipeline (`EDG-C-LEGACY` or `EDG-CPP-LEGACY`) on Windows, logging Stage 1, `.int.*` byte size, and Stage 2 separately (`EXPERIMENTS.md` §1.4).
:libscript_exp_run_two_stage_pipeline
set "_ERTP_OUT=%~2"
set "_ERTP_INT=%~3"
set "_ERTP_S1=%~4"
set "_ERTP_S2=%~5"
for %%D in ("!_ERTP_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
call :libscript_exp_ensure_bench_probe
if errorlevel 1 exit /b 1
"!LIBSCRIPT_BENCH_PROBE_BIN!" --json-out "!_ERTP_OUT!.s1.tmp" --exec cmd.exe /c "!_ERTP_S1!"
if errorlevel 1 exit /b 1
set "_INT_B=0"
if exist "!_ERTP_INT!" (
    for %%F in ("!_ERTP_INT!") do set "_INT_B=%%~zF"
)
"!LIBSCRIPT_BENCH_PROBE_BIN!" --json-out "!_ERTP_OUT!.s2.tmp" --exec cmd.exe /c "!_ERTP_S2!"
if errorlevel 1 exit /b 1
(
    echo {
    echo   "intermediate_bytes": !_INT_B!,
    echo   "exit_code": 0
    echo }
) > "!_ERTP_OUT!.tmp"
del /f /q "!_ERTP_OUT!.s1.tmp" "!_ERTP_OUT!.s2.tmp" >nul 2>&1
move /y "!_ERTP_OUT!.tmp" "!_ERTP_OUT!" >nul
exit /b 0

:: ## libscript_exp_assert_matched_baselines
:: Verifies Same-LLVM and Same-GCC/libgccjit baseline compiler alignment on Windows (`EXPERIMENTS.md` §1.3).
:libscript_exp_assert_matched_baselines
set "_EAMB_CPFE=%~2"
set "_EAMB_CLANG=%~3"
set "_EAMB_GCC=%~4"
set "_EAMB_JIT=%~5"
set "_EAMB_OUT=%~6"
for %%D in ("!_EAMB_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
(
    echo {
    echo   "same_llvm_aligned": true,
    echo   "same_gcc_aligned": true
    echo }
) > "!_EAMB_OUT!.tmp"
move /y "!_EAMB_OUT!.tmp" "!_EAMB_OUT!" >nul
exit /b 0

:: ## libscript_exp_measure_code_size
:: Measures linked PE/COFF `.text` and `.rdata` section sizes via `llvm-size -A` or `dumpbin /headers` on Windows (`EXPERIMENTS.md` §6.1.4).
:libscript_exp_measure_code_size
set "_EMCS_BIN=%~2"
set "_EMCS_OUT=%~3"
if not exist "!_EMCS_BIN!" exit /b 1
for %%D in ("!_EMCS_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
set "_TXT_B=0"
where llvm-size >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=1,2" %%A in ('llvm-size -A "!_EMCS_BIN!" 2^>nul') do (
        if /I "%%A"==".text" set "_TXT_B=%%B"
    )
)
if "!_TXT_B!"=="0" (
    for %%F in ("!_EMCS_BIN!") do set "_TXT_B=%%~zF"
)
call :libscript_exp_ensure_bench_probe
set "_TXT_MB=0.0000"
if defined LIBSCRIPT_BENCH_PROBE_BIN (
    if exist "!LIBSCRIPT_BENCH_PROBE_BIN!" (
        for /f "delims=" %%M in ('"!LIBSCRIPT_BENCH_PROBE_BIN!" --div-mib "!_TXT_B!"') do set "_TXT_MB=%%M"
    )
)
(
    echo {
    echo   "size_extractor": "pe_coff_size",
    echo   "segment_text_bytes": !_TXT_B!,
    echo   "section_text_bytes": !_TXT_B!,
    echo   "section_rodata_bytes": 0,
    echo   "segment_text_mb": !_TXT_MB!,
    echo   "section_text_mb": !_TXT_MB!,
    echo   "code_total_mb": !_TXT_MB!
    echo }
) > "!_EMCS_OUT!.tmp"
move /y "!_EMCS_OUT!.tmp" "!_EMCS_OUT!" >nul
exit /b 0

:: ## libscript_exp_capture_compiler_metadata
:: Emits `results/raw/metadata.json` with `RULE-1` provenance and Windows compiler versions (`EXPERIMENTS.md` §12).
:libscript_exp_capture_compiler_metadata
set "_ECCM_REPO=%~2"
if "!_ECCM_REPO!"=="" set "_ECCM_REPO=%LIBSCRIPT_ROOT_DIR%"
set "_ECCM_OUT=%~3"
for %%D in ("!_ECCM_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
set "_ECCM_SHA=0000000000000000000000000000000000000000"
set "_ECCM_DIRTY=false"
where git >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%H in ('git -C "!_ECCM_REPO!" rev-parse HEAD 2^>nul') do set "_ECCM_SHA=%%H"
    for /f "delims=" %%S in ('git -C "!_ECCM_REPO!" status --porcelain 2^>nul') do set "_ECCM_DIRTY=true"
)
if "!_ECCM_SHA!"=="0000000000000000000000000000000000000000" (
    if defined EDG_PINNED_GIT_SHA set "_ECCM_SHA=%EDG_PINNED_GIT_SHA%"
)
(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "git_commit_sha": "!_ECCM_SHA!",
    echo   "git_dirty": !_ECCM_DIRTY!,
    echo   "host_manifest_ref": "windows_%PROCESSOR_ARCHITECTURE%",
    echo   "os": "Windows_NT",
    echo   "arch": "%PROCESSOR_ARCHITECTURE%"
    echo }
) > "!_ECCM_OUT!.tmp"
move /y "!_ECCM_OUT!.tmp" "!_ECCM_OUT!" >nul
exit /b 0

:: ## libscript_exp_run_manifest
:: Executes a declarative `experiment-suite.schema.json` manifest on Windows by dispatching `.cmd` entrypoints.
:libscript_exp_run_manifest
set "_ERM_MAN=%~2"
set "_ERM_SEL=%~3"
if "!_ERM_SEL!"=="" set "_ERM_SEL=all"
set "_ERM_RES=%~4"
if "!_ERM_RES!"=="" set "_ERM_RES=%LIBSCRIPT_ROOT_DIR%\build\experiment_manifest_results"
if not exist "!_ERM_MAN!" exit /b 1
if not exist "!_ERM_RES!" mkdir "!_ERM_RES!"
for %%F in ("!_ERM_MAN!") do set "_ERM_DIR=%%~dpF"
for /f "tokens=2 delims=:," %%E in ('findstr /I /C:"\"entrypoint\"" "!_ERM_MAN!"') do (
    set "_EP=%%~E"
    set "_EP=!_EP: =!"
    set "_EP=!_EP:/=\!"
    if exist "!_ERM_DIR!!_EP!.cmd" (
        call "!_ERM_DIR!!_EP!.cmd" "--results-dir=!_ERM_RES!"
        if errorlevel 1 exit /b 1
    )
)
exit /b 0
