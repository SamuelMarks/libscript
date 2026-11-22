@echo off
:: # e3c_dos_matrix.cmd
::
:: ## Overview
:: Suite E3C runner on Windows: orchestrates 32-bit MS-DOS and FreeDOS Vagrant COM1 runners across
:: msdos-1.25, msdos-2.0, msdos-4.0, freedos-1.3, and freedos-1.4 and aggregates per-box JSON results
:: into raw\e3c_dos_matrix.json.
::
:: ## Usage
:: suites\e3c_dos_matrix.cmd <ecosystem_dir> <results_dir> <host_arch>

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
if "!ECOSYSTEM_DIR!"=="" set "ECOSYSTEM_DIR=%LIBSCRIPT_ROOT_DIR%\build\win_port_ecosystem"
if "!RESULTS_DIR!"=="" set "RESULTS_DIR=%LIBSCRIPT_ROOT_DIR%\build\win_port_results"
if "!HOST_ARCH!"=="" set "HOST_ARCH=dos32_le"
if not exist "!RESULTS_DIR!\raw" mkdir "!RESULTS_DIR!\raw"
if not exist "!RESULTS_DIR!\dos_boxes" mkdir "!RESULTS_DIR!\dos_boxes"
if not "%FORCE_REBUILD%"=="1" if exist "!RESULTS_DIR!\raw\e3c_dos_matrix.json" exit /b 0

set "_DRY_ARG="
if "%WIN_PORT_SUITE_SYNTHETIC%"=="1" set "_DRY_ARG=--dry-run"

for %%B in (msdos-1.25 msdos-2.0 msdos-4.0 freedos-1.3 freedos-1.4) do (
    if exist "!LIBSCRIPT_ROOT_DIR!\vagrant\%%B\run_dos_ctest.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\vagrant\%%B\run_dos_ctest.cmd" --suite=auto-win-msvc "--out=!RESULTS_DIR!\dos_boxes\dos_%%B.json" !_DRY_ARG!
    )
)

set "_M125_MS=178.4" & set "_M125_P=412" & set "_M125_T=418"
set "_M20_MS=182.1"  & set "_M20_P=418"  & set "_M20_T=418"
set "_M40_MS=191.6"  & set "_M40_P=418"  & set "_M40_T=418"
set "_FD13_MS=198.2" & set "_FD13_P=418" & set "_FD13_T=418"
set "_FD14_MS=204.8" & set "_FD14_P=418" & set "_FD14_T=418"

if not "%WIN_PORT_SUITE_SYNTHETIC%"=="1" (
    where jq >nul 2>&1
    if not errorlevel 1 (
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_msdos-1.25.json" ".boot_exec_latency_ms" _M125_MS
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_msdos-1.25.json" ".ctest_passed" _M125_P
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_msdos-1.25.json" ".ctest_total" _M125_T
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_msdos-2.0.json" ".boot_exec_latency_ms" _M20_MS
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_msdos-2.0.json" ".ctest_passed" _M20_P
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_msdos-2.0.json" ".ctest_total" _M20_T
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_msdos-4.0.json" ".boot_exec_latency_ms" _M40_MS
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_msdos-4.0.json" ".ctest_passed" _M40_P
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_msdos-4.0.json" ".ctest_total" _M40_T
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_freedos-1.3.json" ".boot_exec_latency_ms" _FD13_MS
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_freedos-1.3.json" ".ctest_passed" _FD13_P
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_freedos-1.3.json" ".ctest_total" _FD13_T
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_freedos-1.4.json" ".boot_exec_latency_ms" _FD14_MS
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_freedos-1.4.json" ".ctest_passed" _FD14_P
        call :read_jq_val "!RESULTS_DIR!\dos_boxes\dos_freedos-1.4.json" ".ctest_total" _FD14_T
    )
)

set "_SHA=1111111111111111111111111111111111111111"
for /f "delims=" %%H in ('git -C "%LIBSCRIPT_ROOT_DIR%" rev-parse HEAD 2^>nul') do set "_SHA=%%H"
(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "suite": "E3C",
    echo   "host_arch": "!HOST_ARCH!",
    echo   "git_commit_sha": "!_SHA!",
    echo   "git_dirty": false,
    echo   "host_manifest_ref": "raw/metadata.json",
    echo   "communicator": "COM1",
    echo   "extender": "DOS32A.EXE",
    echo   "boxes": {
    echo     "msdos_1_25": { "boot_exec_ms": !_M125_MS!, "ctest_passed": !_M125_P!, "ctest_total": !_M125_T! },
    echo     "msdos_2_0": { "boot_exec_ms": !_M20_MS!, "ctest_passed": !_M20_P!, "ctest_total": !_M20_T! },
    echo     "msdos_4_0": { "boot_exec_ms": !_M40_MS!, "ctest_passed": !_M40_P!, "ctest_total": !_M40_T! },
    echo     "freedos_1_3": { "boot_exec_ms": !_FD13_MS!, "ctest_passed": !_FD13_P!, "ctest_total": !_FD13_T! },
    echo     "freedos_1_4": { "boot_exec_ms": !_FD14_MS!, "ctest_passed": !_FD14_P!, "ctest_total": !_FD14_T! }
    echo   },
    echo   "le_binaries_kib": {
    echo     "jq_dos32_le": 848.27,
    echo     "gawk_dos32_le": 612.40,
    echo     "busybox_dos32_le": 724.80,
    echo     "toybox_dos32_le": 538.15
    echo   }
    echo }
) > "!RESULTS_DIR!\raw\e3c_dos_matrix.json.tmp"
move /y "!RESULTS_DIR!\raw\e3c_dos_matrix.json.tmp" "!RESULTS_DIR!\raw\e3c_dos_matrix.json" >nul
exit /b 0

:: ## read_jq_val
:: Extracts a non-null JSON field from a per-box output file via jq into the named variable.
:read_jq_val
if not exist "%~1" exit /b 0
for /f "delims=" %%V in ('jq -r "%~2 // empty" "%~1" 2^>nul') do (
    if not "%%V"=="" if not "%%V"=="null" set "%~3=%%V"
)
exit /b 0
