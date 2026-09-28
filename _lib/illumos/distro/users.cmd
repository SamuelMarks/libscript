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
    echo Usage: %~nx0 [sysroot_path] [primary_user]
    echo Configures illumos users and RBAC.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [primary_user]
    echo Configures illumos users and RBAC.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
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
