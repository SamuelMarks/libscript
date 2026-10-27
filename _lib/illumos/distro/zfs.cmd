@echo off
:: # zfs.cmd
::
:: ## Overview
:: Configures canonical illumos ZFS root pool (rpool) layout and vfstab
:: on Windows host environments.
::
:: ## Usage
:: zfs.cmd [sysroot_path] [pool_name] [compression]

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


if "%~1"=="--help" (
    echo Usage: %~nx0 [sysroot_path] [pool_name] [compression]
    echo Configures illumos ZFS root pool and dataset structure.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [pool_name] [compression]
    echo Configures illumos ZFS root pool and dataset structure.
    exit /b 0
)

set "REPO_ROOT=!SCRIPT_DIR!\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "POOL_NAME=%~2"
if "%POOL_NAME%"=="" set "POOL_NAME=rpool"
set "COMPRESSION=%~3"
if "%COMPRESSION%"=="" set "COMPRESSION=lz4"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\zfs.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"
if not exist "%SYSROOT%\boot" mkdir "%SYSROOT%\boot"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos ZFS storage layout already configured in %SYSROOT%
    exit /b 0
)

echo [ZFS]      Configuring illumos ZFS dataset hierarchy (pool: %POOL_NAME%, compression: %COMPRESSION%)...

(
    echo # Illumos ZFS Root Pool Layout (managed by LibScript^)
    echo %POOL_NAME%                    mountpoint=none,canmount=off
    echo %POOL_NAME%/ROOT               mountpoint=none,canmount=off
    echo %POOL_NAME%/ROOT/illumos       mountpoint=legacy,canmount=noauto,compression=%COMPRESSION%,bootfs=yes
    echo %POOL_NAME%/export             mountpoint=/export,canmount=off
    echo %POOL_NAME%/export/home        mountpoint=/export/home,canmount=on,compression=%COMPRESSION%
    echo %POOL_NAME%/dump               volsize=2G,canmount=off
    echo %POOL_NAME%/swap               volsize=2G,canmount=off
) > "%SYSROOT%\etc\zfs-datasets.conf"

(
    echo # /etc/vfstab: Virtual File System Table (managed by LibScript^)
    echo /devices        -               /devices        devfs   -       no      -
    echo /proc           -               /proc           proc    -       no      -
    echo ctfs            -               /system/contract ctfs   -       no      -
    echo objfs           -               /system/object  objfs   -       no      -
    echo swap            -               /tmp            tmpfs   -       yes     -
    echo /dev/zfs        -               /               zfs     -       yes     -
    echo /dev/zvol/dsk/%POOL_NAME%/swap - -             swap    -       no      -
) > "%SYSROOT%\etc\vfstab"

findstr /C:"zfs_load=" "%SYSROOT%\boot\loader.conf" >nul 2>&1
if errorlevel 1 (
    echo zfs_load="YES"
    echo vfs.root.mountfrom="zfs:%POOL_NAME%/ROOT/illumos"
) >> "%SYSROOT%\boot\loader.conf"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos ZFS storage layout configured.
exit /b 0
