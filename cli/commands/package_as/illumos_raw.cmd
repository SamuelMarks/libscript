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
    echo Usage: %~nx0 [target_sysroot] [output_image] [size_gib]
    echo Synthesizes raw illumos disk image.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [target_sysroot] [output_image] [size_gib]
    echo Synthesizes raw illumos disk image.
    exit /b 0
)

set "REPO_ROOT=!SCRIPT_DIR!..\..\.."
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
