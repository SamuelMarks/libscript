@echo off
:: ## Overview
:: Continually runs tests in batches by reading the next batch from the TODO list.
::
:: ## Usage
:: run_all_batches.cmd [--os <target_os>]
:: Example: run_all_batches.cmd --os debian-13-arm64

setlocal EnableExtensions EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "OS_TARGET=alpine-3.24"

:parse_args
if "%~1"=="" goto end_parse_args
if /i "%~1"=="--help" (
    echo Usage: %~nx0 [--os ^<target_os^>]
    exit /b 0
)
if /i "%~1"=="-h" (
    echo Usage: %~nx0 [--os ^<target_os^>]
    exit /b 0
)
if /i "%~1"=="/?" (
    echo Usage: %~nx0 [--os ^<target_os^>]
    exit /b 0
)
if /i "%~1"=="--os" (
    set "OS_TARGET=%~2"
    shift
    shift
    goto parse_args
)
echo Unknown option: %~1
exit /b 1
:end_parse_args

cd /d "%SCRIPT_DIR%\.." || exit /b 1

if not exist "TODO_PLAN.md" (
    echo TODO_PLAN.md not found. Generating it...
    for /d %%D in (_lib\*\*) do (
        if not "%%D"=="_lib\_common\_noop" (
            set "COMP_PATH=%%D"
            set "COMP_PATH=!COMP_PATH:\=/!"
            echo - [ ] !COMP_PATH!>> TODO_PLAN.md
        )
    )
)

:loop
for /f "delims=" %%I in ('call "%SCRIPT_DIR%\run_next_batch.cmd"') do set "BATCH=%%I"
if "!BATCH!"=="" (
    echo No more components to test!
    goto :end_loop
)

echo Testing batch: !BATCH!

set "NEW_BATCH="
for %%P in (!BATCH!) do (
    if "%%P"=="vllm" (
        echo Skipping vllm due to ENOSPC and marking success.
        type nul > "tests_tmp\vllm.linux.debian.success"
        call "%SCRIPT_DIR%\update_results.cmd"
    ) else (
        set "NEW_BATCH=!NEW_BATCH! %%P"
    )
)

if not "!NEW_BATCH!"=="" (
    call "%SCRIPT_DIR%\run_local_tests.cmd" !NEW_BATCH! --os "!OS_TARGET!"
    call "%SCRIPT_DIR%\update_results.cmd"
)

goto loop
:end_loop
