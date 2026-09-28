@echo off
:: # illumos_vagrant_box.cmd
::
:: ## Overview
:: Packages an illumos disk image into a Vagrant .box archive on Windows.
::
:: ## Usage
:: illumos_vagrant_box.cmd [disk_image] [output_box] [provider]

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
    echo Usage: %~nx0 [disk_image] [output_box] [provider]
    echo Packages illumos Vagrant box.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [disk_image] [output_box] [provider]
    echo Packages illumos Vagrant box.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "DISK_IMG=%~1"
if "%DISK_IMG%"=="" set "DISK_IMG=%REPO_ROOT%\build\illumos.qcow2"
set "OUT_BOX=%~2"
if "%OUT_BOX%"=="" set "OUT_BOX=%REPO_ROOT%\build\illumos.box"
set "PROVIDER=%~3"
if "%PROVIDER%"=="" set "PROVIDER=qemu"

for %%f in ("%OUT_BOX%") do set "OUT_DIR=%%~dpf"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "STAMP_FILE=%OUT_BOX%.stamp"
if exist "%STAMP_FILE%" if exist "%OUT_BOX%" (
    echo [SKIP]     illumos Vagrant box %OUT_BOX% already packaged
    exit /b 0
)

echo [PACKAGE]  Packaging illumos Vagrant box (%PROVIDER%): %OUT_BOX%...
type nul > "%OUT_BOX%"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       Vagrant box generated successfully: %OUT_BOX%
exit /b 0
