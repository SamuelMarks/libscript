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

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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
    echo Usage: %~nx0 [sysroot_path] [hostname] [dhcp]
    echo Configures illumos core system files.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [hostname] [dhcp]
    echo Configures illumos core system files.
    exit /b 0
)

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
