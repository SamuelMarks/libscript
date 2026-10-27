@echo off
:: # users.cmd
::
:: ## Overview
:: Provisions user accounts, sudoers rules, and SSH authorized keys inside
:: the FreeBSD target sysroot from Windows.
::
:: ## Usage
:: users.cmd [sysroot_path] [primary_user]

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
    echo Usage: %~nx0 [sysroot_path] [primary_user]
    echo Provisions users and SSH authorized keys in FreeBSD sysroot.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [primary_user]
    echo Provisions users and SSH authorized keys in FreeBSD sysroot.
    exit /b 0
)

set "REPO_ROOT=!SCRIPT_DIR!\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"
set "PRIMARY_USER=%~2"
if "%PRIMARY_USER%"=="" set "PRIMARY_USER=vagrant"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\users.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\usr\local\etc\sudoers.d" mkdir "%SYSROOT%\usr\local\etc\sudoers.d"
if not exist "%SYSROOT%\home\%PRIMARY_USER%\.ssh" mkdir "%SYSROOT%\home\%PRIMARY_USER%\.ssh"
if not exist "%SYSROOT%\root\.ssh" mkdir "%SYSROOT%\root\.ssh"

if exist "%STAMP_FILE%" (
    echo [SKIP]     FreeBSD users already provisioned in %SYSROOT%
    exit /b 0
)

echo [USERS]    Provisioning user accounts and security policies (%PRIMARY_USER%)...

(
    echo # doas.conf ^(managed by LibScript^)
    echo permit nopass keepenv :wheel
    echo permit nopass keepenv root
) > "%SYSROOT%\usr\local\etc\doas.conf"

(
    echo # sudoers rule for wheel group ^(managed by LibScript^)
    echo %%wheel ALL=^(ALL:ALL^) NOPASSWD: ALL
) > "%SYSROOT%\usr\local\etc\sudoers.d\00-wheel-nopass"

set "KEY=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLX6OKMQe1tRJyUk2LaKOqq4TLncREaqq5461b4wuSiUcMSKncsysyrsF21jrr5RsMtZVCnB955iVDD57Gh/O5KeGq88hEl7ZgpTNY4LCmpMZPV3NFWWDtYnuUIIggbJYJvKeOtnBgN+/yV+JQVCyb++t5xRQ3CzCd5KsvYXvRauMQBQjzcUuc276Q== vagrant insecure public key"

echo !KEY!> "%SYSROOT%\home\%PRIMARY_USER%\.ssh\authorized_keys"
echo !KEY!> "%SYSROOT%\root\.ssh\authorized_keys"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       FreeBSD user provisioning completed.
exit /b 0
