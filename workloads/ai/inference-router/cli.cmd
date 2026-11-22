@echo off
:: # cli.cmd
:: ## Overview
:: CLI router for multi-worker Cloud TPU training jobs on Windows delegating to `workloads\schedulers\tpu_vm.cmd`.
:: ## Usage
:: cli.cmd <submit|status|logs|stop|destroy|install|test> [payload.json]

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
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "ACT=%~1"
if "!ACT!"=="" set "ACT=status"
if /i "!ACT!"=="--help" ( echo Usage: cli.cmd ^<submit^|status^|logs^|stop^|destroy^|test^> [payload.json] & exit /b 0 )
if /i "!ACT!"=="-h" ( echo Usage: cli.cmd ^<submit^|status^|logs^|stop^|destroy^|test^> [payload.json] & exit /b 0 )
if /i "!ACT!"=="install" exit /b 0
if /i "!ACT!"=="test" ( call "!SCRIPT_DIR!\test.cmd" & exit /b !errorlevel! )
if /i "!ACT!"=="deploy" set "ACT=submit"
if /i "!ACT!"=="teardown" set "ACT=destroy"
set "PF=%~2"
if "!PF!"=="" set "PF=!LIBSCRIPT_ROOT_DIR!\workloads\payloads\ai\gcp-tpu-vm\payload.json"
call "!LIBSCRIPT_ROOT_DIR!\workloads\schedulers\tpu_vm.cmd" "!ACT!" "!PF!" %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!
