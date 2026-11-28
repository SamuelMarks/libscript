@echo off
:: # test.cmd
:: ## Overview
:: Smoke validation, Stage A SHA-256 distinctness guard check, and idempotent A/B LaTeX synthesis test for `gemma-4-sql-libtpu` on Windows.
:: ## Usage
:: test.cmd

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
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Validates suite manifest, dry-run, and idempotent A/B synthesis.
:root_found
call "!LIBSCRIPT_ROOT_DIR!\experiments\engine.cmd" validate "gemma-4-sql-libtpu" >nul
if errorlevel 1 exit /b !errorlevel!
set "_TMP=%TEMP%\g4s_ab_smoke_!RANDOM!"
if not exist "!_TMP!\out\og\raw" mkdir "!_TMP!\out\og\raw"
if not exist "!_TMP!\out\rs\raw" mkdir "!_TMP!\out\rs\raw"
set "STACK="
call "!SCRIPT_DIR!\run.cmd" --dry-run "--repo-dir=!_TMP!" "--results-dir=!_TMP!\out" >nul
if errorlevel 1 exit /b 1
> "!_TMP!\out\og\raw\e0_provenance.json" echo {"suite":"E0","libtpu_provider":"og","stage_a_probes":[{"backend_id":"jax_native","libtpu_mapped_so_sha256":"aaaa1111"}]}
> "!_TMP!\out\rs\raw\e0_provenance.json" echo {"suite":"E0","libtpu_provider":"rs","stage_a_probes":[{"backend_id":"jax_native","libtpu_mapped_so_sha256":"bbbb2222"}]}
set "STACK="
call "!SCRIPT_DIR!\run.cmd" --render-latex "--repo-dir=!_TMP!" "--results-dir=!_TMP!\out" "--backends=jax_native" >nul
if errorlevel 1 exit /b 1
set "STACK="
call "!SCRIPT_DIR!\run.cmd" --render-latex "--repo-dir=!_TMP!" "--results-dir=!_TMP!\out" "--backends=jax_native" >nul
if errorlevel 1 exit /b 1
if not exist "!_TMP!\out\ab_comparison_summary.json" exit /b 1
if not exist "!_TMP!\out\generated_metrics.tex" exit /b 1
rmdir /s /q "!_TMP!" >nul 2>&1
exit /b 0
