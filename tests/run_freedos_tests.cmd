@echo off
:: # run_freedos_tests.cmd
::
:: ## Overview
:: Runs tests sequentially for LibScript components on a local FreeDOS Vagrant VM (bento/freedos-1.3
:: or bento/freedos-1.4) on Windows using Bento::VagrantFreedos, vanilla snapshot restoration, and
:: 2x idempotency verification.
::
:: ## Usage
:: tests\run_freedos_tests.cmd [TARGETS...|all] [--os freedos-1.3|freedos-1.4] [--snapshot vanilla] [--boot-only]

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

set "FREEDOS_OS=freedos-1.3"
if not defined BENTO_DIR set "BENTO_DIR=!LIBSCRIPT_ROOT_DIR!\..\bento"
for %%A in (x86_64 aarch64 i386) do (
    if exist "!BENTO_DIR!\builds\build_complete\freedos-1.4-%%A.qemu.box" set "FREEDOS_OS=freedos-1.4"
)
set "FORWARD_ARGS="

call :parse_fd_args %*
if errorlevel 2 exit /b 0

set "STACK="
call "!SCRIPT_DIR!\run_local_tests.cmd" --os "!FREEDOS_OS!" --reuse-vm !FORWARD_ARGS!
exit /b !ERRORLEVEL!

:: ## parse_fd_args
:: Parses CLI options for run_freedos_tests.cmd.
:parse_fd_args
if "%~1"=="" exit /b 0
set "_FA=%~1"
if /I "!_FA!"=="--help" goto :show_fd_help
if /I "!_FA!"=="-h" goto :show_fd_help
if /I "!_FA!"=="/?" goto :show_fd_help
if /I "!_FA!"=="--os" ( set "FREEDOS_OS=%~2" & shift & shift & goto :parse_fd_args )
if /I "!_FA:~0,5!"=="--os=" ( set "FREEDOS_OS=!_FA:~5!" & shift & goto :parse_fd_args )
set "FORWARD_ARGS=!FORWARD_ARGS! %1"
shift
goto :parse_fd_args

:: ## show_fd_help
:: Displays usage instructions and returns exit code 2.
:show_fd_help
echo Usage: %~nx0 [TARGETS...^|all] [--os freedos-1.3^|freedos-1.4] [--snapshot vanilla] [--boot-only]
echo Runs LibScript DOS component verification on a local Bento FreeDOS Vagrant VM.
exit /b 2
