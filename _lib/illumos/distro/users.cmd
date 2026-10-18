@echo off
:: # users.cmd
::
:: ## Overview
:: Configures illumos user accounts, RBAC execution profiles, and sudoers
:: on Windows host environments.
::
:: ## Usage
:: users.cmd [sysroot_path] [primary_user]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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
    echo Configures illumos users and RBAC.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [primary_user]
    echo Configures illumos users and RBAC.
    exit /b 0
)

set "REPO_ROOT=!SCRIPT_DIR!..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "PRIMARY_USER=%~2"
if "%PRIMARY_USER%"=="" set "PRIMARY_USER=vagrant"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\users.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"
if not exist "%SYSROOT%\etc\sudoers.d" mkdir "%SYSROOT%\etc\sudoers.d"
if not exist "%SYSROOT%\export\home\%PRIMARY_USER%\.ssh" mkdir "%SYSROOT%\export\home\%PRIMARY_USER%\.ssh"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos users and RBAC already provisioned in %SYSROOT%
    exit /b 0
)

echo [USERS]    Provisioning illumos user accounts and RBAC (user: %PRIMARY_USER%)...

(
    echo root:x:0:0:Super-User:/root:/bin/sh
    echo %PRIMARY_USER%:x:1000:10:%PRIMARY_USER% User:/export/home/%PRIMARY_USER%:/bin/sh
) > "%SYSROOT%/etc/passwd"

(
    echo root::19000::::::
    echo %PRIMARY_USER%::19000::::::
) > "%SYSROOT%/etc/shadow"

(
    echo root::0:
    echo staff::10:%PRIMARY_USER%
    echo sysadmin::14:%PRIMARY_USER%
) > "%SYSROOT%/etc/group"

(
    echo root::::type=normal;auths=solaris.*;profiles=All
    echo %PRIMARY_USER%::::type=normal;profiles=Primary Administrator;defaultpriv=basic
) > "%SYSROOT%/etc/user_attr"

echo %PRIMARY_USER% ALL=(ALL) NOPASSWD: ALL> "%SYSROOT%/etc/sudoers.d/%PRIMARY_USER%"
echo permit nopass %PRIMARY_USER% as root> "%SYSROOT%/etc/doas.conf"

(
    echo export PATH="/usr/bin:/usr/sbin:/sbin:/opt/local/bin:/opt/local/sbin"
    echo export PAGER="cat"
    echo export EDITOR="vi"
) > "%SYSROOT%/export/home/%PRIMARY_USER%/.profile"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos user accounts and RBAC provisioned.
exit /b 0
