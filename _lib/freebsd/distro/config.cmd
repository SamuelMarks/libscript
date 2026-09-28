@echo off
:: # config.cmd
::
:: ## Overview
:: Configures core FreeBSD configuration files inside target sysroot
:: (/boot/loader.conf, /etc/rc.conf, /etc/fstab, /etc/ttys) on Windows.
::
:: ## Usage
:: config.cmd [sysroot_path] [hostname] [filesystem]

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
    echo Usage: %~nx0 [sysroot_path] [hostname] [filesystem]
    echo Configures core FreeBSD system configuration.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [hostname] [filesystem]
    echo Configures core FreeBSD system configuration.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"
set "HOSTNAME=%~2"
if "%HOSTNAME%"=="" set "HOSTNAME=freebsd-distro"
set "FILESYSTEM=%~3"
if "%FILESYSTEM%"=="" set "FILESYSTEM=ufs2"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\config.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\boot" mkdir "%SYSROOT%\boot"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"

if exist "%STAMP_FILE%" (
    echo [SKIP]     FreeBSD core configuration already applied in %SYSROOT%
    exit /b 0
)

echo [CONFIG]   Configuring core FreeBSD files (hostname=%HOSTNAME%, fs=%FILESYSTEM%)...

(
    echo # FreeBSD Bootloader Configuration ^(managed by LibScript^)
    echo autoboot_delay="2"
    echo boot_multicons="YES"
    echo boot_serial="YES"
    echo comconsole_speed="115200"
    echo console="comconsole,vidconsole"
) > "%SYSROOT%\boot\loader.conf"

if "%FILESYSTEM%"=="zfs" (
    echo zfs_load="YES">> "%SYSROOT%\boot\loader.conf"
    echo vfs.root.mountfrom="zfs:zroot/ROOT/default">> "%SYSROOT%\boot\loader.conf"
)

(
    echo # FreeBSD System Configuration ^(managed by LibScript^)
    echo hostname="%HOSTNAME%"
    echo ifconfig_DEFAULT="DHCP"
    echo sshd_enable="YES"
    echo sendmail_enable="NONE"
    echo dumpdev="NO"
) > "%SYSROOT%\etc\rc.conf"

if "%FILESYSTEM%"=="zfs" (
    echo zfs_enable="YES">> "%SYSROOT%\etc\rc.conf"
)

if "%FILESYSTEM%"=="zfs" (
    (
        echo # Device        Mountpoint      FStype  Options Dump    Pass#
        echo /dev/gpt/efiboot0 /boot/efi     msdosfs rw,noatime 0    0
    ) > "%SYSROOT%\etc\fstab"
) else (
    (
        echo # Device        Mountpoint      FStype  Options Dump    Pass#
        echo /dev/gpt/rootfs   /               ufs     rw,noatime 1    1
        echo /dev/gpt/efiboot0 /boot/efi       msdosfs rw,noatime 0    0
    ) > "%SYSROOT%\etc\fstab"
)

(
    echo nameserver 1.1.1.1
    echo nameserver 8.8.8.8
) > "%SYSROOT%\etc\resolv.conf"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       Core configuration generated successfully.
exit /b 0
