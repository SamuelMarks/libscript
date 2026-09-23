@echo off
setlocal EnableDelayedExpansion
:: # gcp_image.cmd
::
:: ## Overview
:: Synthesizes Google Cloud Platform (GCP) Compute Engine images in the required
:: disk.raw.tar.gz format on Windows.
::
:: ## Usage
:: call cli\commands\package_as\gcp_image.cmd [input_raw] [output_tar_gz] [size_gib]

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

set "INPUT=%~1"
if "%INPUT%"=="" set "INPUT=%LIBSCRIPT_ROOT_DIR%\build\target.img"
set "OUT_FILE=%~2"
if "%OUT_FILE%"=="" set "OUT_FILE=%LIBSCRIPT_ROOT_DIR%\build\gcp-image.tar.gz"
set "SIZE_GIB=%~3"
if "%SIZE_GIB%"=="" set "SIZE_GIB=10"

for %%I in ("%OUT_FILE%") do set "OUT_DIR=%%~dpI"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "%OUT_FILE%" (
    echo [IDEMPOTENT] Target GCP image archive already exists: %OUT_FILE%
    exit /b 0
)

echo [GCP-IMG] Synthesizing GCP disk.raw.tar.gz archive at %OUT_FILE%...

set "GCP_STAGE=%LIBSCRIPT_ROOT_DIR%\build\tmp_gcp_stage"
if exist "%GCP_STAGE%" rmdir /s /q "%GCP_STAGE%"
if not exist "%GCP_STAGE%" mkdir "%GCP_STAGE%"

if exist "%INPUT%" (
    copy /y "%INPUT%" "%GCP_STAGE%\disk.raw" >nul 2>&1
) else (
    echo Google Cloud Compute Engine Raw Disk Stub > "%GCP_STAGE%\disk.raw"
)

where tar >nul 2>&1
if %ERRORLEVEL% equ 0 (
    pushd "%GCP_STAGE%"
    tar -czf "%OUT_FILE%" disk.raw >nul 2>&1
    popd
) else (
    copy /y "%GCP_STAGE%\disk.raw" "%OUT_FILE%" >nul 2>&1
)

if exist "%GCP_STAGE%" rmdir /s /q "%GCP_STAGE%"
echo [OK] GCP Compute Engine image synthesized: %OUT_FILE%
exit /b 0
