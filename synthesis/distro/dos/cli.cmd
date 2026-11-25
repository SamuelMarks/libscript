@echo off
:: # cli.cmd
::
:: ## Overview
:: CLI router for synthesis\distro\dos on Windows supporting assemble, install, test, and uninstall.
::
:: ## Usage
:: synthesis\distro\dos\cli.cmd <assemble^|install^|test^|uninstall> [args...]

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

set "ACT=%~1"
if "!ACT!"=="" set "ACT=%ACTION%"
if "!ACT!"=="" set "ACT=assemble"
if /I "!ACT!"=="--help" (
    echo Usage: %~nx0 ^<assemble^|install^|test^|uninstall^> [sysroot] [out_img]
    exit /b 0
)
if /I "!ACT!"=="test" (
    set "STACK="
    call "!SCRIPT_DIR!\test.cmd"
    exit /b !errorlevel!
)
if /I "!ACT!"=="uninstall" (
    set "STACK="
    call "!SCRIPT_DIR!\uninstall.cmd"
    exit /b !errorlevel!
)
set "_ARG_SYS=%~2"
set "_ARG_OUT=%~3"
if /I "!ACT!"=="install" (
    if /I "!_ARG_SYS!"=="latest" (
        set "_ARG_SYS=%~3"
        set "_ARG_OUT=%~4"
    ) else if /I "!_ARG_SYS!"=="stable" (
        set "_ARG_SYS=%~3"
        set "_ARG_OUT=%~4"
    )
)
if /I "!ACT!"=="bootstrap" (
    if /I "!_ARG_SYS!"=="latest" (
        set "_ARG_SYS=%~3"
        set "_ARG_OUT=%~4"
    ) else if /I "!_ARG_SYS!"=="stable" (
        set "_ARG_SYS=%~3"
        set "_ARG_OUT=%~4"
    )
)
set "STACK="
call "!SCRIPT_DIR!\assemble.cmd" "!_ARG_SYS!" "!_ARG_OUT!"
exit /b !errorlevel!
