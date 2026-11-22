@echo off
:: # filesystem.cmd
::
:: ## Overview
:: Configures the ReactOS root filesystem driver (fat32, btrfs, or ntfs) and freeldr.ini serial options on Windows.
::
:: ## Usage
:: synthesis\distro\reactos\filesystem.cmd [sysroot_path] [filesystem] [serial_debug]

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
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"
set "FS_TYPE=%~2"
if "!FS_TYPE!"=="" set "FS_TYPE=fat32"
set "SERIAL_DEBUG=%~3"
if "!SERIAL_DEBUG!"=="" set "SERIAL_DEBUG=true"

set "STAMP_DIR=!SYSROOT!\.libscript-stamps"
set "STAMP_FILE=!STAMP_DIR!\filesystem_!FS_TYPE!.stamp"
set "ISO_ROOT=!SYSROOT!\iso_root"

if exist "!STAMP_FILE!" (
    echo [SKIP]     ReactOS filesystem ^(!FS_TYPE!^) already configured in !SYSROOT!
    exit /b 0
)
if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"
if not exist "!ISO_ROOT!\reactos\system32\drivers" mkdir "!ISO_ROOT!\reactos\system32\drivers"

if /I "!FS_TYPE!"=="fat32" (
    echo driver=fastfat.sys> "!ISO_ROOT!\reactos\filesystem.conf"
    if not exist "!ISO_ROOT!\reactos\system32\drivers\fastfat.sys" echo FASTFAT_SYS> "!ISO_ROOT!\reactos\system32\drivers\fastfat.sys"
) else if /I "!FS_TYPE!"=="btrfs" (
    echo driver=btrfs.sys> "!ISO_ROOT!\reactos\filesystem.conf"
    if not exist "!ISO_ROOT!\reactos\system32\drivers\btrfs.sys" echo WINBTRFS_SYS> "!ISO_ROOT!\reactos\system32\drivers\btrfs.sys"
) else if /I "!FS_TYPE!"=="ntfs" (
    echo driver=ntfs.sys> "!ISO_ROOT!\reactos\filesystem.conf"
    if not exist "!ISO_ROOT!\reactos\system32\drivers\ntfs.sys" echo NTFS_SYS> "!ISO_ROOT!\reactos\system32\drivers\ntfs.sys"
) else (
    echo [ERROR] Unsupported ReactOS filesystem "!FS_TYPE!". >&2
    exit /b 1
)

if /I "!SERIAL_DEBUG!"=="true" if exist "!ISO_ROOT!\freeldr.ini" (
    findstr /I /C:"/DEBUGPORT=COM1" "!ISO_ROOT!\freeldr.ini" >nul 2>&1
    if errorlevel 1 echo Options=/FASTDETECT /DEBUG /DEBUGPORT=COM1 /BAUDRATE=115200 /SOS>> "!ISO_ROOT!\freeldr.ini"
)

echo configured> "!STAMP_FILE!"
echo [OK]       ReactOS filesystem ^(!FS_TYPE!^) configured.
exit /b 0
