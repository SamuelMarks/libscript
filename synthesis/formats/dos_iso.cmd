@echo off
:: # dos_iso.cmd
::
:: ## Overview
:: Packages a synthesized DOS sysroot into an El Torito bootable ISO9660 image on Windows.
::
:: ## Usage
:: synthesis\formats\dos_iso.cmd <sysroot_dir> <output.iso>

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

set "_STG=%TEMP%\dos_iso_!RANDOM!"
if not exist "!_STG!\BOOT" mkdir "!_STG!\BOOT"
for %%D in ("%~2") do if not exist "%%~dpD" mkdir "%%~dpD"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\dos\live_dos.cmd" "%~1" "!_STG!\BOOT\FLOPPY.IMG"
if errorlevel 1 exit /b 1
where xorriso.exe >nul 2>&1
if not errorlevel 1 (
    xorriso.exe -as mkisofs -quiet -R -J -V "LIBSCRIPDOS" -b BOOT/FLOPPY.IMG -c BOOT/BOOT.CAT -o "%~2" "!_STG!"
    rmdir /s /q "!_STG!"
    exit /b 0
)
copy /y "!_STG!\BOOT\FLOPPY.IMG" "%~2" >nul
rmdir /s /q "!_STG!"
exit /b 0
