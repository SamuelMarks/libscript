@echo off
:: # test_parallel_precommit.cmd
:: ## Overview
:: Hermetic Windows Batch unit and integration test suite for `engine\common\parallel.cmd` and
:: `.githooks\pre-commit.cmd`, verifying `LIBSCRIPT_JOBS` overrides, concurrent worker pools,
:: error propagation, MS-DOS (`IS_MSDOS=1`) graceful sequential fallback, and 2x idempotency.
:: ## Usage
:: tests\test_parallel_precommit.cmd

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

if /I "%~1"=="--mock-item" goto :mock_item_worker
if /I "%~1"=="--fail-item" goto :fail_item_worker
if /I "%~1"=="--mock-shard" goto :mock_shard_worker

set /a "CHECKS=0"
set /a "FAILURES=0"
set "_TP_DIR=%TEMP%\lsp_test_!RANDOM!_!RANDOM!"
if not exist "!_TP_DIR!" mkdir "!_TP_DIR!"

echo === 1. Testing parallel.cmd Job Detection ^& MS-DOS Fallback ===

set "IS_MSDOS="
set "LIBSCRIPT_DOS_83="
set "LIBSCRIPT_JOBS=4"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :detect_jobs
if "!LIBSCRIPT_RESOLVED_JOBS!"=="4" (
    call :pass_check "LIBSCRIPT_JOBS=4 override resolved 4 workers"
) else (
    call :fail_check "Expected LIBSCRIPT_JOBS=4 -> 4, got !LIBSCRIPT_RESOLVED_JOBS!"
)

set "IS_MSDOS=1"
set "LIBSCRIPT_JOBS=8"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :detect_jobs
set "IS_MSDOS="
set "LIBSCRIPT_JOBS="
if "!LIBSCRIPT_RESOLVED_JOBS!"=="1" (
    if "!LIBSCRIPT_PARALLEL_SUPPORTED!"=="0" (
        call :pass_check "IS_MSDOS=1 gracefully fell back to sequential mode (JOBS=1, PARALLEL=0)"
    ) else (
        call :fail_check "IS_MSDOS=1 left LIBSCRIPT_PARALLEL_SUPPORTED=!LIBSCRIPT_PARALLEL_SUPPORTED!"
    )
) else (
    call :fail_check "IS_MSDOS=1 did not resolve JOBS=1 (got !LIBSCRIPT_RESOLVED_JOBS!)"
)

echo === 2. Testing Concurrent Task Execution ^& Failure Propagation ===

set "_TASKS_OK=!_TP_DIR!\TASKS_OK.TXT"
>"!_TASKS_OK!" echo call "!THIS_FILE!" --mock-item "!_TP_DIR!\A.OUT"
>>"!_TASKS_OK!" echo call "!THIS_FILE!" --mock-item "!_TP_DIR!\B.OUT"
>>"!_TASKS_OK!" echo call "!THIS_FILE!" --mock-item "!_TP_DIR!\C.OUT"

set "LIBSCRIPT_JOBS=3"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :run_tasks "!_TASKS_OK!" 3
set "_OK_RC=!ERRORLEVEL!"
if "!_OK_RC!"=="0" (
    if exist "!_TP_DIR!\A.OUT" (
        if exist "!_TP_DIR!\C.OUT" (
            call :pass_check "parallel.cmd :run_tasks completed all 3 concurrent tasks cleanly"
        ) else (
            call :fail_check "Missing C.OUT from concurrent task run"
        )
    ) else (
        call :fail_check "Missing A.OUT from concurrent task run"
    )
) else (
    call :fail_check "Expected :run_tasks rc=0, got !_OK_RC!"
)

set "_TASKS_BAD=!_TP_DIR!\TASKS_BAD.TXT"
>"!_TASKS_BAD!" echo call "!THIS_FILE!" --mock-item "!_TP_DIR!\D.OUT"
>>"!_TASKS_BAD!" echo call "!THIS_FILE!" --fail-item

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :run_tasks "!_TASKS_BAD!" 2
if errorlevel 1 (
    call :pass_check "parallel.cmd :run_tasks propagated failing worker exit status"
) else (
    call :fail_check "parallel.cmd :run_tasks failed to propagate worker error"
)

set "IS_MSDOS=1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :run_tasks "!_TASKS_BAD!" 2
if errorlevel 1 (
    call :pass_check "IS_MSDOS=1 sequential fallback propagated failing worker exit status"
) else (
    call :fail_check "IS_MSDOS=1 sequential fallback failed to propagate worker error"
)
set "IS_MSDOS="
set "LIBSCRIPT_JOBS="

echo === 3. Testing parallel.cmd :run_shards Worker+Flag Quoting ===

set "_SHARD_IN=!_TP_DIR!\SHARD_IN.TXT"
>"!_SHARD_IN!" echo !_TP_DIR!\S_ITEM1.OUT
>>"!_SHARD_IN!" echo !_TP_DIR!\S_ITEM2.OUT
>>"!_SHARD_IN!" echo !_TP_DIR!\S_ITEM3.OUT

set "LIBSCRIPT_JOBS=2"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :run_shards "!_SHARD_IN!" "!THIS_FILE! --mock-shard" 2
set "_SH_RC=!ERRORLEVEL!"
if "!_SH_RC!"=="0" (
    if exist "!_TP_DIR!\S_ITEM1.OUT" (
        if exist "!_TP_DIR!\S_ITEM3.OUT" (
            call :pass_check "parallel.cmd :run_shards split script.cmd --mock-shard and processed all shards"
        ) else (
            call :fail_check "Missing S_ITEM3.OUT from :run_shards worker+flag run"
        )
    ) else (
        call :fail_check "Missing S_ITEM1.OUT from :run_shards worker+flag run"
    )
) else (
    call :fail_check "Expected :run_shards rc=0, got !_SH_RC!"
)

del /f /q "!_TP_DIR!\S_ITEM1.OUT" "!_TP_DIR!\S_ITEM2.OUT" "!_TP_DIR!\S_ITEM3.OUT" >nul 2>&1
set "IS_MSDOS=1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :run_shards "!_SHARD_IN!" "!THIS_FILE! --mock-shard" 2
set "_SH_DOS_RC=!ERRORLEVEL!"
set "IS_MSDOS="
set "LIBSCRIPT_JOBS="
if "!_SH_DOS_RC!"=="0" (
    if exist "!_TP_DIR!\S_ITEM2.OUT" (
        call :pass_check "IS_MSDOS=1 :run_shards sequential fallback split script.cmd --mock-shard cleanly"
    ) else (
        call :fail_check "Missing S_ITEM2.OUT from IS_MSDOS=1 :run_shards fallback"
    )
) else (
    call :fail_check "Expected IS_MSDOS=1 :run_shards rc=0, got !_SH_DOS_RC!"
)

if exist "!_TP_DIR!" rmdir /s /q "!_TP_DIR!" >nul 2>&1

REM wincheck disable=CMD2003
if !FAILURES! gtr 0 (
    echo [FAIL] Parallel Pre-Commit Batch Suite failed ^(!FAILURES!/!CHECKS! checks failed^) 1>&2
    exit /b 1
)
echo === All !CHECKS! Parallel Pre-Commit Batch Checks Passed^^! ===
exit /b 0

:: ## pass_check
:: Records and prints a passing test check.
:pass_check
set /a "CHECKS+=1"
echo [PASS] %~1
exit /b 0

:: ## fail_check
:: Records and prints a failing test check.
:fail_check
set /a "CHECKS+=1"
set /a "FAILURES+=1"
echo [FAIL] %~1 1>&2
exit /b 0

:: ## mock_item_worker
:: Writes an output marker file for a parallel worker test item.
:mock_item_worker
>"%~2" echo ok
exit /b 0

:: ## fail_item_worker
:: Exits with status 1 to test parallel worker failure propagation.
:fail_item_worker
exit /b 1

:: ## mock_shard_worker
:: Writes an output marker file for every item listed in shard file %~2.
:mock_shard_worker
set "_MSW_F=%~2"
if "!_MSW_F!"=="" exit /b 1
if not exist "!_MSW_F!" exit /b 1
for /f "usebackq delims=" %%M in ("!_MSW_F!") do (
    >"%%M" echo shard_ok
)
exit /b 0
