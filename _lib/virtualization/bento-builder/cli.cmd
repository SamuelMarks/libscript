@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Bento Builder stack on Windows, supporting standard Version
:: Manager verbs via component_core.cmd plus build, box, and register delegation to setup_generic.cmd.
::
:: ## Usage
:: _lib\virtualization\bento-builder\cli.cmd [install|build|box|register|test|ls|use|uninstall] [args...]

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

if /i "%~1"=="build" goto :dispatch_bento_action
if /i "%~1"=="box" goto :dispatch_bento_action
if /i "%~1"=="register" goto :dispatch_bento_action

set "PACKAGE_NAME=bento-builder"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\component_core.cmd" %*
exit /b !ERRORLEVEL!

:: ## dispatch_bento_action
:: Parses build/box/register flags and dispatches to setup_generic.cmd.
:dispatch_bento_action
set "ACTION=%~1"
shift

:: ## parse_bento_args
:: Iterates through remaining CLI arguments for build/box/register actions.
:parse_bento_args
if "%~1"=="" goto :run_bento_setup
set "_BA=%~1"
if /i "!_BA!"=="--bento-dir" (
    set "BENTO_DIR=%~2"
    shift
    shift
    goto :parse_bento_args
)
if /i "!_BA:~0,12!"=="--bento-dir=" (
    set "BENTO_DIR=!_BA:~12!"
    shift
    goto :parse_bento_args
)
if /i "!_BA!"=="--force" (
    set "BENTO_BUILDER_FORCE_REBUILD=1"
    shift
    goto :parse_bento_args
)
if /i "!_BA!"=="--force-rebuild" (
    set "BENTO_BUILDER_FORCE_REBUILD=1"
    shift
    goto :parse_bento_args
)
if "!_BA:~0,1!"=="-" (
    shift
    goto :parse_bento_args
)
if "!BENTO_BUILDER_TARGET_OS!"=="" set "BENTO_BUILDER_TARGET_OS=!_BA!"
shift
goto :parse_bento_args

:: ## run_bento_setup
:: Invokes setup_generic.cmd with parsed ACTION and BENTO_BUILDER_* variables.
:run_bento_setup
set "STACK="
call "!SCRIPT_DIR!\setup_generic.cmd"
exit /b !ERRORLEVEL!
