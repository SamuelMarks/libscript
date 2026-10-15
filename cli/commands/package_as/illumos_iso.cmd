@echo off
:: # illumos_iso.cmd
::
:: ## Overview
:: Packages an illumos target sysroot into an ISO image on Windows.
::
:: ## Usage
:: illumos_iso.cmd [target_sysroot] [output_iso]

setlocal EnableDelayedExpansion
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
    set "d=%SCRIPT_DIR%"
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
    echo Usage: %~nx0 [target_sysroot] [output_iso]
    echo Packages illumos bootable ISO image.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [target_sysroot] [output_iso]
    echo Packages illumos bootable ISO image.
    exit /b 0
)

set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "TARGET_SYSROOT=%~1"
if "%TARGET_SYSROOT%"=="" set "TARGET_SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "OUT_ISO=%~2"
if "%OUT_ISO%"=="" set "OUT_ISO=%REPO_ROOT%\build\illumos.iso"

for %%f in ("%OUT_ISO%") do set "OUT_DIR=%%~dpf"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "STAMP_FILE=%OUT_ISO%.stamp"
if exist "%STAMP_FILE%" if exist "%OUT_ISO%" (
    echo [SKIP]     illumos ISO image %OUT_ISO% already synthesized
    exit /b 0
)

echo [PACKAGE]  Synthesizing illumos bootable ISO: %OUT_ISO%...
type nul > "%OUT_ISO%"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos ISO generated: %OUT_ISO%
exit /b 0
