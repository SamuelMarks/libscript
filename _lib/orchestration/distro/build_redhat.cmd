@echo off
setlocal EnableDelayedExpansion
:: # build_redhat.cmd
::
:: ## Overview
:: Executes the end-to-end Red Hat-inspired distribution synthesis pipeline on Windows:
:: creating FHS layout, initializing RPM/DNF structure, packaging base RPMs,
:: generating repository repodata, and configuring target system identity.
::
:: ## Usage
:: call _lib\orchestration\distro\build_redhat.cmd [--target-rootfs=<path>]

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
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "TARGET_ROOTFS=%LIBSCRIPT_ROOT_DIR%\build\rootfs_redhat"
if not "%~1"=="" set "TARGET_ROOTFS=%~1"

echo [DISTRO-REDHAT] Initializing Red Hat-inspired distribution synthesis pipeline...
echo [DISTRO-REDHAT] Target rootfs: %TARGET_ROOTFS%

if not exist "%TARGET_ROOTFS%" mkdir "%TARGET_ROOTFS%"

set "STAMP_FILE=%TARGET_ROOTFS%\.redhat_distro_built"
if exist "%STAMP_FILE%" (
    echo [IDEMPOTENT] Red Hat distribution already synthesized at: %TARGET_ROOTFS%
    exit /b 0
)

echo [DISTRO-REDHAT] Phase 1: Creating FHS directory layout...
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\create_fhs_layout.cmd" "%TARGET_ROOTFS%"

echo [DISTRO-REDHAT] Phase 2: Initializing RPM database and DNF repository configs...
if not exist "%TARGET_ROOTFS%\var\lib\rpm" mkdir "%TARGET_ROOTFS%\var\lib\rpm"
if not exist "%TARGET_ROOTFS%\etc\yum.repos.d" mkdir "%TARGET_ROOTFS%\etc\yum.repos.d"
if not exist "%TARGET_ROOTFS%\etc\dnf" mkdir "%TARGET_ROOTFS%\etc\dnf"

(
    echo [main]
    echo gpgcheck=1
    echo installonly_limit=3
) > "%TARGET_ROOTFS%\etc\dnf\dnf.conf"

(
    echo [libscript-base]
    echo name=LibScript Distribution Base
    echo baseurl=file:///var/lib/libscript/repo/rpm
    echo enabled=1
    echo gpgcheck=0
) > "%TARGET_ROOTFS%\etc\yum.repos.d\libscript.repo"

echo [DISTRO-REDHAT] Phase 3 and 4: Generating base RPM packages and repodata...
set "PACKAGES_OUT=%LIBSCRIPT_ROOT_DIR%\build\packages\rpm"
if not exist "%PACKAGES_OUT%" mkdir "%PACKAGES_OUT%"

call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\packagers\build_rpm.cmd" "redhat-release" "9.4" "%TARGET_ROOTFS%" "%PACKAGES_OUT%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\repogen\rpm_index.cmd" "%PACKAGES_OUT%"

echo [DISTRO-REDHAT] Phase 5: Finalizing Red Hat system identity...
(
    echo NAME="LibScript Enterprise Linux (Red Hat-style)"
    echo ID=rhel
    echo ID_LIKE=fedora
    echo VERSION_ID="9.4"
    echo PRETTY_NAME="LibScript Enterprise Linux 9.4"
) > "%TARGET_ROOTFS%\etc\os-release"

echo LibScript Enterprise Linux release 9.4 > "%TARGET_ROOTFS%\etc\redhat-release"

type nul > "%STAMP_FILE%"
echo [OK] Red Hat-inspired distribution synthesis complete at: %TARGET_ROOTFS%
exit /b 0
