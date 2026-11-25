@echo off
:: # dpmi.cmd
::
:: ## Overview
:: Stages 32-bit CWSDPMI.EXE, DJGPP.ENV, and guest LIBSCRIP.BAT on Windows when targeting dos32-dpmi.
::
:: ## Usage
:: synthesis\distro\dos\dpmi.cmd [sysroot_dir]

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

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
if not "%LIBSCRIPT_DOS_STRATUM%"=="" if /I not "%LIBSCRIPT_DOS_STRATUM%"=="dos32-dpmi" exit /b 0
set "LIBSCRIPT_IMAGE_BUILD=1"
set "LIBSCRIPT_TARGET_SYSROOT=!SYSROOT!"
set "ACTION=install"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\djgpp\setup.cmd"
if errorlevel 1 exit /b 1
if not exist "!SYSROOT!\LIBSCRIP\BIN" mkdir "!SYSROOT!\LIBSCRIP\BIN"
if not exist "!SYSROOT!\TMP" mkdir "!SYSROOT!\TMP"
(
    echo @ECHO OFF
    echo ECHO [LIBSCRIPT] DOS 32-bit DPMI guest runtime active
) > "!SYSROOT!\LIBSCRIP\LIBSCRIP.BAT"
exit /b 0
