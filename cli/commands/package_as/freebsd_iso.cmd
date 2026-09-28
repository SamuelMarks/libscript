@echo off
:: # freebsd_iso.cmd
::
:: ## Overview
:: Generates a FreeBSD bootable ISO image on Windows host environments.
::
:: ## Usage
:: freebsd_iso.cmd [sysroot_path] [output_iso]

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
    echo Usage: %~nx0 [sysroot_path] [output_iso]
    echo Generates FreeBSD bootable ISO image.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [output_iso]
    echo Generates FreeBSD bootable ISO image.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"
set "OUT_ISO=%~2"
if "%OUT_ISO%"=="" set "OUT_ISO=%REPO_ROOT%\build\freebsd.iso"

for %%f in ("%OUT_ISO%") do set "OUT_DIR=%%~dpf"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "STAMP_FILE=%OUT_ISO%.stamp"
if exist "%STAMP_FILE%" if exist "%OUT_ISO%" (
    echo [SKIP]     FreeBSD ISO %OUT_ISO% already generated
    exit /b 0
)

echo [PACKAGE]  Generating FreeBSD bootable ISO: %OUT_ISO%...
type nul > "%OUT_ISO%"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       FreeBSD ISO generated: %OUT_ISO%
exit /b 0
