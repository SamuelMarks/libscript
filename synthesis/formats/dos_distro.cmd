@echo off
:: # dos_distro.cmd
::
:: ## Overview
:: Unified Windows CLI entrypoint to synthesize and package a FreeDOS or MIT MS-DOS distribution profile.
::
:: ## Usage
:: synthesis\formats\dos_distro.cmd [--format <qcow2^|floppy-img^|raw^|iso^|vagrant-box>] [--profile <profile.json>] [--output <path>] [--dry-run]

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

set "FORMAT=%LIBSCRIPT_DOS_DEFAULT_FORMAT%"
if "!FORMAT!"=="" set "FORMAT=qcow2"
set "PROFILE=%LIBSCRIPT_DOS_DEFAULT_PROFILE%"
if "!PROFILE!"=="" set "PROFILE=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\dos\freedos-1.4-djgpp-i586.json"
set "OUTPUT="
set "FWD="
goto :parse_dd

:: ## parse_dd
:: Parses CLI flags for dos_distro.cmd.
:parse_dd
if "%~1"=="" goto :run_dd
set "_A=%~1"
if /I "!_A!"=="--help" (
    echo Usage: %~nx0 [--format ^<qcow2^|floppy-img^|raw^|iso^|vagrant-box^>] [--profile ^<profile.json^>] [--output ^<path^>] [--dry-run]
    exit /b 0
)
if /I "!_A!"=="--format" ( set "FORMAT=%~2" & shift & shift & goto :parse_dd )
if /I "!_A:~0,9!"=="--format=" ( set "FORMAT=!_A:~9!" & shift & goto :parse_dd )
if /I "!_A!"=="--profile" ( set "PROFILE=%~2" & shift & shift & goto :parse_dd )
if /I "!_A:~0,10!"=="--profile=" ( set "PROFILE=!_A:~10!" & shift & goto :parse_dd )
if /I "!_A!"=="--output" ( set "OUTPUT=%~2" & shift & shift & goto :parse_dd )
if /I "!_A!"=="--out" ( set "OUTPUT=%~2" & shift & shift & goto :parse_dd )
if /I "!_A:~0,9!"=="--output=" ( set "OUTPUT=!_A:~9!" & shift & goto :parse_dd )
if /I "!_A:~0,6!"=="--out=" ( set "OUTPUT=!_A:~6!" & shift & goto :parse_dd )
if /I "!_A!"=="--dry-run" ( set "FWD=!FWD! --dry-run" & shift & goto :parse_dd )
shift
goto :parse_dd

:: ## run_dd
:: Resolves target DOS kernel variant and dispatches synthesize-image.cmd.
:run_dd
if not exist "!PROFILE!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\dos\!PROFILE!.json" set "PROFILE=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\dos\!PROFILE!.json"
set "KERN=freedos"
findstr /I /C:"msdos-mit-4.0" "!PROFILE!" >nul 2>&1 && set "KERN=msdos-4.0"
findstr /I /C:"msdos-mit-2.0" "!PROFILE!" >nul 2>&1 && set "KERN=msdos-2.0"
findstr /I /C:"msdos-mit-1.25" "!PROFILE!" >nul 2>&1 && set "KERN=msdos-1.25"
set "STACK="
if not "!OUTPUT!"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\synthesize-image.cmd" "--kernel=!KERN!" "--profile=!PROFILE!" "--format=!FORMAT!" "--out=!OUTPUT!" !FWD!
    exit /b !errorlevel!
)
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\synthesize-image.cmd" "--kernel=!KERN!" "--profile=!PROFILE!" "--format=!FORMAT!" !FWD!
exit /b !errorlevel!
