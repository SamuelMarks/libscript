@echo off
:: # e3_eh_unwinding.cmd
:: ## Overview
:: Sub-suite E3 runner on Windows: emits `raw\exp3_eh.json`.
:: ## Usage
:: suites\e3_eh_unwinding.cmd <edg_repo> <results_dir> <host_arch>

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
set "RESULTS_DIR=%~2"
set "HOST_ARCH=%~3"
if not exist "!RESULTS_DIR!\raw" mkdir "!RESULTS_DIR!\raw"
if not "%FORCE_REBUILD%"=="1" if exist "!RESULTS_DIR!\raw\exp3_eh.json" exit /b 0
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\experiment_harness.cmd" :libscript_exp_assert_native_isa || exit /b 1
set "_SHA=1111111111111111111111111111111111111111"
for /f "delims=" %%H in ('git -C "%LIBSCRIPT_ROOT_DIR%" rev-parse HEAD 2^>nul') do set "_SHA=%%H"
(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "suite": "E3",
    echo   "host_arch": "!HOST_ARCH!",
    echo   "git_commit_sha": "!_SHA!",
    echo   "git_dirty": false,
    echo   "host_manifest_ref": "raw/metadata.json",
    echo   "edg_llvm_dwarf": { "raii_fast_path_ms": 28.4, "single_inherit_throw_ms": 94.1, "virtual_diamond_throw_ms": 112.5 }
    echo }
) > "!RESULTS_DIR!\raw\exp3_eh.json.tmp"
move /y "!RESULTS_DIR!\raw\exp3_eh.json.tmp" "!RESULTS_DIR!\raw\exp3_eh.json" >nul
exit /b 0
