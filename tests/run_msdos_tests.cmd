@echo off
:: # run_msdos_tests.cmd
::
:: ## Overview
:: Runs tests sequentially for LibScript components on a local Microsoft MS-DOS Vagrant VM
:: (bento/msdos-4.0, bento/msdos-2.0, or bento/msdos-1.25) on Windows using Bento::VagrantMsdos,
:: vanilla snapshot restoration, and 2x idempotency verification.
::
:: ## Usage
:: tests\run_msdos_tests.cmd [TARGETS...|all] [--os msdos-4.0|msdos-2.0|msdos-1.25] [--snapshot vanilla] [--boot-only]

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

if "!MSDOS_OS!"=="" set "MSDOS_OS=msdos-4.0"
set "FORWARD_ARGS="

call :parse_md_args %*
if errorlevel 2 exit /b 0

set "STACK="
call "!SCRIPT_DIR!\run_local_tests.cmd" --os "!MSDOS_OS!" --reuse-vm !FORWARD_ARGS!
exit /b !ERRORLEVEL!

:: ## parse_md_args
:: Parses CLI options for run_msdos_tests.cmd.
:parse_md_args
if "%~1"=="" exit /b 0
set "_MA=%~1"
if /I "!_MA!"=="--help" goto :show_md_help
if /I "!_MA!"=="-h" goto :show_md_help
if /I "!_MA!"=="/?" goto :show_md_help
if /I "!_MA!"=="--os" ( set "MSDOS_OS=%~2" & shift & shift & goto :parse_md_args )
if /I "!_MA:~0,5!"=="--os=" ( set "MSDOS_OS=!_MA:~5!" & shift & goto :parse_md_args )
set "FORWARD_ARGS=!FORWARD_ARGS! %1"
shift
goto :parse_md_args

:: ## show_md_help
:: Displays usage instructions and returns exit code 2.
:show_md_help
echo Usage: %~nx0 [TARGETS...^|all] [--os msdos-4.0^|msdos-2.0^|msdos-1.25] [--snapshot vanilla] [--boot-only]
echo Runs LibScript DOS component verification on a local Bento MS-DOS Vagrant VM.
exit /b 2
