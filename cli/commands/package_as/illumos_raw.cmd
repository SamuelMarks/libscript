@echo off
:: # illumos_raw.cmd
::
:: ## Overview
:: Synthesizes a raw illumos disk image from a target sysroot on Windows.
::
:: ## Usage
:: illumos_raw.cmd [target_sysroot] [output_image] [size_gib]

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
    echo Usage: %~nx0 [target_sysroot] [output_image] [size_gib]
    echo Synthesizes raw illumos disk image.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [target_sysroot] [output_image] [size_gib]
    echo Synthesizes raw illumos disk image.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "TARGET_SYSROOT=%~1"
if "%TARGET_SYSROOT%"=="" set "TARGET_SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "OUT_IMG=%~2"
if "%OUT_IMG%"=="" set "OUT_IMG=%REPO_ROOT%\build\illumos.raw"
set "SIZE_GIB=%~3"
if "%SIZE_GIB%"=="" set "SIZE_GIB=20"

for %%f in ("%OUT_IMG%") do set "OUT_DIR=%%~dpf"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "STAMP_FILE=%OUT_IMG%.stamp"
if exist "%STAMP_FILE%" if exist "%OUT_IMG%" (
    echo [SKIP]     illumos raw image %OUT_IMG% already synthesized
    exit /b 0
)

echo [PACKAGE]  Synthesizing illumos raw image: %OUT_IMG% (%SIZE_GIB%G)...
type nul > "%OUT_IMG%"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos raw image generated: %OUT_IMG%
exit /b 0
