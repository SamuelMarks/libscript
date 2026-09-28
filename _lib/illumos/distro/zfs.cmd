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

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

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

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
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

(
    echo zfs_load="YES"
    echo vfs.root.mountfrom="zfs:%POOL_NAME%/ROOT/illumos"
) >> "%SYSROOT%\boot\loader.conf"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos ZFS storage layout configured.
exit /b 0
