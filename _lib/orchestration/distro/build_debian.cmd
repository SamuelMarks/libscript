@echo off
setlocal EnableDelayedExpansion
:: # build_debian.cmd
::
:: ## Overview
:: Executes the end-to-end Debian-style distribution synthesis pipeline on Windows:
:: creating FHS layout, bootstrapping dpkg/apt structure, synthesizing base .deb
:: packages, generating APT repository, and registering installed status.
::
:: ## Usage
:: call _lib\orchestration\distro\build_debian.cmd [--target-rootfs=<path>]

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

set "TARGET_ROOTFS=%LIBSCRIPT_ROOT_DIR%\build\rootfs_debian"
if not "%~1"=="" set "TARGET_ROOTFS=%~1"

echo [DISTRO-DEBIAN] Initializing Debian-style distribution synthesis pipeline...
echo [DISTRO-DEBIAN] Target rootfs: %TARGET_ROOTFS%

if not exist "%TARGET_ROOTFS%" mkdir "%TARGET_ROOTFS%"

set "STAMP_FILE=%TARGET_ROOTFS%\.debian_distro_built"
if exist "%STAMP_FILE%" (
    echo [IDEMPOTENT] Debian distribution already synthesized at: %TARGET_ROOTFS%
    exit /b 0
)

echo [DISTRO-DEBIAN] Phase 1: Creating FHS layout and system skeleton...
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\create_fhs_layout.cmd" "%TARGET_ROOTFS%"

echo [DISTRO-DEBIAN] Phase 2: Bootstrapping dpkg and apt administrative state...
if not exist "%TARGET_ROOTFS%\var\lib\dpkg\info" mkdir "%TARGET_ROOTFS%\var\lib\dpkg\info"
if not exist "%TARGET_ROOTFS%\var\lib\dpkg\updates" mkdir "%TARGET_ROOTFS%\var\lib\dpkg\updates"
if not exist "%TARGET_ROOTFS%\var\lib\dpkg\alternatives" mkdir "%TARGET_ROOTFS%\var\lib\dpkg\alternatives"
if not exist "%TARGET_ROOTFS%\etc\apt\sources.list.d" mkdir "%TARGET_ROOTFS%\etc\apt\sources.list.d"
if not exist "%TARGET_ROOTFS%\etc\apt\apt.conf.d" mkdir "%TARGET_ROOTFS%\etc\apt\apt.conf.d"
if not exist "%TARGET_ROOTFS%\etc\apt\trusted.gpg.d" mkdir "%TARGET_ROOTFS%\etc\apt\trusted.gpg.d"

type nul > "%TARGET_ROOTFS%\var\lib\dpkg\status"
type nul > "%TARGET_ROOTFS%\var\lib\dpkg\available"

(
    echo deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
    echo deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
) > "%TARGET_ROOTFS%\etc\apt\sources.list"

(
    echo APT::Install-Recommends "0";
    echo APT::Install-Suggests "0";
) > "%TARGET_ROOTFS%\etc\apt\apt.conf.d\01libscript"

echo [DISTRO-DEBIAN] Phase 3 and 4: Generating base packages and APT repository...
set "PACKAGES_OUT=%LIBSCRIPT_ROOT_DIR%\build\packages\deb"
if not exist "%PACKAGES_OUT%" mkdir "%PACKAGES_OUT%"

call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\packagers\build_deb.cmd" "base-files" "12.4" "%TARGET_ROOTFS%" "%PACKAGES_OUT%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\repogen\deb_index.cmd" "%PACKAGES_OUT%" "bookworm" "amd64" "main"

echo [DISTRO-DEBIAN] Phase 5: Finalizing package manager status database...
(
    echo Package: base-files
    echo Status: install ok installed
    echo Priority: required
    echo Section: admin
    echo Installed-Size: 10
    echo Maintainer: LibScript OS Synthesizer ^<libscript@local^>
    echo Architecture: amd64
    echo Version: 12.4
    echo Description: LibScript Debian Base System Files
    echo  Core filesystem architecture and os-release identification.
    echo.
) >> "%TARGET_ROOTFS%\var\lib\dpkg\status"

(
    echo NAME="LibScript GNU/Linux (Debian-style)"
    echo ID=debian
    echo ID_LIKE=libscript
    echo VERSION_ID="12"
    echo PRETTY_NAME="LibScript Debian-style GNU/Linux"
) > "%TARGET_ROOTFS%\etc\os-release"

type nul > "%STAMP_FILE%"
echo [OK] Debian-style distribution synthesis complete at: %TARGET_ROOTFS%
exit /b 0
