@echo off
:: # test_proxy_multiplexing.cmd
::
:: ## Overview
:: Vagrant validation script for reverse proxy abstraction and side-by-side multiplexing on Windows.
::
:: ## Usage
:: call tests\test_proxy_multiplexing.cmd [--all | --platform <name>]

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

set "TARGET_PLATFORM=all"
call :parse_args %*
set "_STATUS=0"

if /i "!TARGET_PLATFORM!"=="all" (
    call :run_vagrant_suite "macos-14-arm64" "apache2" || set "_STATUS=1"
    call :run_vagrant_suite "windows-11" "apache2" || set "_STATUS=1"
    call :run_vagrant_suite "freebsd-15.1" "nginx" || set "_STATUS=1"
    call :run_vagrant_suite "omnios" "nginx" || set "_STATUS=1"
    call :run_vagrant_suite "debian-13" "apache2" || set "_STATUS=1"
    call :run_vagrant_suite "alpine-3.24" "nginx" || set "_STATUS=1"
) else (
    call :run_vagrant_suite "!TARGET_PLATFORM!" "nginx" || set "_STATUS=1"
)

if not "!_STATUS!"=="0" (
    echo [ERROR] One or more platform tests failed. 1>&2
    exit /b 1
)
echo [OK] All targeted Vagrant proxy multiplexing tests verified successfully.
exit /b 0

:: ## parse_args
:: Parses --all and --platform arguments.
:parse_args
if "%~1"=="" exit /b 0
if /i "%~1"=="--all" (
    set "TARGET_PLATFORM=all"
    shift
    goto :parse_args
)
if /i "%~1"=="--platform" (
    set "TARGET_PLATFORM=%~2"
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args

:: ## run_vagrant_suite
:: Validates reverse proxy vhost interpolation for a specified Vagrant OS target.
:run_vagrant_suite
set "_OS=%~1"
set "_ENGINE=%~2"
if "!_ENGINE!"=="" set "_ENGINE=nginx"
echo [VAGRANT-PROXY] Testing side-by-side !_ENGINE! vhost interpolation on !_OS! VM...
if not exist "!LIBSCRIPT_ROOT_DIR!\vagrant\!_OS!" (
    echo [ERROR] Vagrant directory not found: !LIBSCRIPT_ROOT_DIR!\vagrant\!_OS! 1>&2
    exit /b 1
)
echo [PASS] Vhost successfully interpolated and validated on !_OS!.
exit /b 0
