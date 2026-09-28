@echo off
:: # config.cmd
::
:: ## Overview
:: Configures core illumos system files: /etc/nodename, /etc/hosts,
:: /etc/default/login, and /boot/loader.conf on Windows host environments.
::
:: ## Usage
:: config.cmd [sysroot_path] [hostname] [dhcp]

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
    echo Usage: %~nx0 [sysroot_path] [hostname] [dhcp]
    echo Configures illumos core system files.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [hostname] [dhcp]
    echo Configures illumos core system files.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "HOSTNAME=%~2"
if "%HOSTNAME%"=="" set "HOSTNAME=illumos-distro"
set "USE_DHCP=%~3"
if "%USE_DHCP%"=="" set "USE_DHCP=true"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\config.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"
if not exist "%SYSROOT%\etc\default" mkdir "%SYSROOT%\etc\default"
if not exist "%SYSROOT%\boot" mkdir "%SYSROOT%\boot"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos core configuration already applied in %SYSROOT%
    exit /b 0
)

echo [CONFIG]   Configuring core illumos files (hostname=%HOSTNAME%, dhcp=%USE_DHCP%)...

echo %HOSTNAME%> "%SYSROOT%\etc\nodename"

(
    echo # IPv4 and IPv6 hosts table (managed by LibScript^)
    echo 127.0.0.1       localhost
    echo ::1             localhost
    echo 127.0.0.1       %HOSTNAME%
    echo ::1             %HOSTNAME%
) > "%SYSROOT%\etc\hosts"

(
    echo # Solaris / illumos login defaults
    echo CONSOLE=/dev/console
    echo PASSREQ=YES
    echo UMASK=022
    echo PATH=/usr/bin:/usr/sbin:/sbin
    echo SUPATH=/usr/sbin:/usr/bin:/sbin
) > "%SYSROOT%\etc\default\login"

(
    echo # DNS resolver configuration (managed by LibScript^)
    echo nameserver 1.1.1.1
    echo nameserver 8.8.8.8
) > "%SYSROOT%\etc\resolv.conf"

(
    echo # illumos Loader Configuration (managed by LibScript^)
    echo autoboot_delay="2"
    echo boot_multicons="YES"
    echo boot_serial="YES"
    echo console="ttya,text"
    echo ttya-mode="115200,8,n,1,-"
    echo os_console="ttya"
) > "%SYSROOT%\boot\loader.conf"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos core configuration complete.
exit /b 0
