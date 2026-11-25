@echo off
:: # dos_vmdk.cmd
::
:: ## Overview
:: Converts a synthesized DOS raw disk image into vmdk format on Windows via qemu-img.
::
:: ## Usage
:: synthesis\formats\dos_vmdk.cmd <sysroot_dir> <output.vmdk>

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

set "_RAW=%~2.raw.tmp"
set "STACK="
call "!SCRIPT_DIR!\dos_raw.cmd" "%~1" "!_RAW!"
if errorlevel 1 exit /b 1
where qemu-img.exe >nul 2>&1
if not errorlevel 1 (
    qemu-img.exe convert -f raw -O vmdk "!_RAW!" "%~2"
    del /f /q "!_RAW!" >nul 2>&1
    exit /b 0
)
move /y "!_RAW!" "%~2" >nul
exit /b 0
