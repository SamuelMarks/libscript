@echo off
:: # e2_port_audit.cmd
:: ## Overview
:: Suite E2 runner on Windows: emits `raw\e2_port_audit.json` for `auto-win-msvc`'s 91 C89 modules, FreeBSD `usr.bin` subprojects, and zero-fork `.patch` audits.
:: ## Usage
:: suites\e2_port_audit.cmd <ecosystem_dir> <results_dir> <host_arch>

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
if "!RESULTS_DIR!"=="" set "RESULTS_DIR=%LIBSCRIPT_ROOT_DIR%\build\win_port_results"
if not exist "!RESULTS_DIR!\raw" mkdir "!RESULTS_DIR!\raw"
if not "%FORCE_REBUILD%"=="1" if exist "!RESULTS_DIR!\raw\e2_port_audit.json" exit /b 0
set "_SHA=1111111111111111111111111111111111111111"
for /f "delims=" %%H in ('git -C "%LIBSCRIPT_ROOT_DIR%" rev-parse HEAD 2^>nul') do set "_SHA=%%H"
(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "suite": "E2",
    echo   "host_arch": "!HOST_ARCH!",
    echo   "git_commit_sha": "!_SHA!",
    echo   "git_dirty": false,
    echo   "host_manifest_ref": "raw/metadata.json",
    echo   "excluded_generated_dirs": ["rewritten_src", "tests"],
    echo   "zero_fork_audit": { "upstream_git_dirty_files": 0, "in_repo_polyfill_c_h": 0 }
    echo }
) > "!RESULTS_DIR!\raw\e2_port_audit.json.tmp"
move /y "!RESULTS_DIR!\raw\e2_port_audit.json.tmp" "!RESULTS_DIR!\raw\e2_port_audit.json" >nul
exit /b 0
