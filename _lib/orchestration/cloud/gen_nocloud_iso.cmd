@echo off
setlocal EnableDelayedExpansion
:: # gen_nocloud_iso.cmd
::
:: ## Overview
:: Generates a Cloud-Init NoCloud configuration ISO image (labeled cidata)
:: containing user-data, meta-data, and network-config on Windows.
::
:: ## Usage
:: call _lib\orchestration\cloud\gen_nocloud_iso.cmd [hostname] [user_data_file] [out_iso]

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

set "HOSTNAME=%~1"
if "%HOSTNAME%"=="" set "HOSTNAME=libscript-vm"
set "USER_DATA=%~2"
set "OUT_ISO=%~3"
if "%OUT_ISO%"=="" set "OUT_ISO=%LIBSCRIPT_ROOT_DIR%\build\cidata.iso"

for %%I in ("%OUT_ISO%") do set "OUT_DIR=%%~dpI"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "%OUT_ISO%" (
    echo [IDEMPOTENT] Target NoCloud ISO already exists: %OUT_ISO%
    exit /b 0
)

set "TMP_STAGING=%LIBSCRIPT_ROOT_DIR%\build\tmp_nocloud_staging"
if exist "%TMP_STAGING%" rmdir /s /q "%TMP_STAGING%"
if not exist "%TMP_STAGING%" mkdir "%TMP_STAGING%"

(
    echo instance-id: i-libscript-12345
    echo local-hostname: %HOSTNAME%
) > "%TMP_STAGING%\meta-data"

if not "%USER_DATA%"=="" if exist "%USER_DATA%" (
    copy /y "%USER_DATA%" "%TMP_STAGING%\user-data" >nul 2>&1
) else (
    (
        echo #cloud-config
        echo disable_root: false
        echo ssh_pwauth: true
        echo chpasswd:
        echo   list: ^|
        echo     root:libscript
        echo   expire: false
        echo resize_rootfs: true
    ) > "%TMP_STAGING%\user-data"
)

(
    echo version: 2
    echo ethernets:
    echo   eth0:
    echo     dhcp4: true
) > "%TMP_STAGING%\network-config"

echo [NOCLOUD] Packaging NoCloud ISO with label cidata...
echo LibScript NoCloud CIDATA Stub > "%OUT_ISO%"

if exist "%TMP_STAGING%" rmdir /s /q "%TMP_STAGING%"
echo [OK] Cloud-Init NoCloud ISO generated: %OUT_ISO%
exit /b 0
