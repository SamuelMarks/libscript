@echo off
setlocal EnableDelayedExpansion
:: # build_alpine.cmd
::
:: ## Overview
:: Executes the end-to-end Alpine Linux-style distribution synthesis pipeline on Windows:
:: creating FHS layout, initializing apk-tools configuration, packaging base APKs,
:: indexing repository metadata, and registering installed status.
::
:: ## Usage
:: call _lib\orchestration\distro\build_alpine.cmd [--target-rootfs=<path>]

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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "TARGET_ROOTFS=%LIBSCRIPT_ROOT_DIR%\build\rootfs_alpine"
if not "%~1"=="" set "TARGET_ROOTFS=%~1"

echo [DISTRO-ALPINE] Initializing Alpine Linux-style distribution synthesis pipeline...
echo [DISTRO-ALPINE] Target rootfs: %TARGET_ROOTFS%

if not exist "%TARGET_ROOTFS%" mkdir "%TARGET_ROOTFS%"

set "STAMP_FILE=%TARGET_ROOTFS%\.alpine_distro_built"
if exist "%STAMP_FILE%" (
    echo [IDEMPOTENT] Alpine distribution already synthesized at: %TARGET_ROOTFS%
    exit /b 0
)

echo [DISTRO-ALPINE] Phase 1: Creating FHS directory layout...
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\create_fhs_layout.cmd" "%TARGET_ROOTFS%"

echo [DISTRO-ALPINE] Phase 2: Initializing apk-tools directories and repositories...
if not exist "%TARGET_ROOTFS%\etc\apk\keys" mkdir "%TARGET_ROOTFS%\etc\apk\keys"
if not exist "%TARGET_ROOTFS%\lib\apk\db" mkdir "%TARGET_ROOTFS%\lib\apk\db"
if not exist "%TARGET_ROOTFS%\var\cache\apk" mkdir "%TARGET_ROOTFS%\var\cache\apk"

(
    echo https://dl-cdn.alpinelinux.org/alpine/v3.20/main
    echo https://dl-cdn.alpinelinux.org/alpine/v3.20/community
) > "%TARGET_ROOTFS%\etc\apk\repositories"

(
    echo alpine-base
    echo busybox
    echo openrc
) > "%TARGET_ROOTFS%\etc\apk\world"

echo [DISTRO-ALPINE] Phase 3 and 4: Generating base APK packages and APKINDEX...
set "PACKAGES_OUT=%LIBSCRIPT_ROOT_DIR%\build\packages\apk"
if not exist "%PACKAGES_OUT%" mkdir "%PACKAGES_OUT%"

call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\packagers\build_apk.cmd" "alpine-base" "3.20.0" "%TARGET_ROOTFS%" "%PACKAGES_OUT%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\repogen\apk_index.cmd" "%PACKAGES_OUT%" "x86_64" "v3.20"

echo [DISTRO-ALPINE] Phase 5: Registering installed packages in APK database...
(
    echo C:Q1dummyhash
    echo P:alpine-base
    echo V:3.20.0
    echo A:x86_64
    echo S:4096
    echo I:4096
    echo T:Alpine Base Meta Package
    echo U:https://alpinelinux.org
    echo L:MIT
    echo o:alpine-base
    echo m:LibScript Maintainer ^<libscript@local^>
    echo t:1700000000
    echo c:none
    echo D:busybox openrc
    echo p:alpine-base=3.20.0
    echo.
) > "%TARGET_ROOTFS%\lib\apk\db\installed"

(
    echo NAME="LibScript Alpine Linux"
    echo ID=alpine
    echo ID_LIKE=libscript
    echo VERSION_ID="3.20.0"
    echo PRETTY_NAME="LibScript Alpine-style Linux v3.20"
) > "%TARGET_ROOTFS%\etc\os-release"

type nul > "%STAMP_FILE%"
echo [OK] Alpine Linux-style distribution synthesis complete at: %TARGET_ROOTFS%
exit /b 0
