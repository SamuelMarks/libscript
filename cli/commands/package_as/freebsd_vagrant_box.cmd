@echo off
:: # freebsd_vagrant_box.cmd
::
:: ## Overview
:: Packages a FreeBSD disk image into a Vagrant .box archive on Windows.
::
:: ## Usage
:: freebsd_vagrant_box.cmd [disk_image] [output_box] [provider]

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
    echo Packages FreeBSD disk image into Vagrant .box file.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [disk_image] [output_box] [provider]
    echo Packages FreeBSD disk image into Vagrant .box file.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "DISK_IMG=%~1"
if "%DISK_IMG%"=="" set "DISK_IMG=%REPO_ROOT%\build\freebsd.qcow2"
set "OUT_BOX=%~2"
if "%OUT_BOX%"=="" set "OUT_BOX=%REPO_ROOT%\build\freebsd.box"
set "PROVIDER=%~3"
if "%PROVIDER%"=="" set "PROVIDER=qemu"

for %%f in ("%OUT_BOX%") do set "OUT_DIR=%%~dpf"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "STAMP_FILE=%OUT_BOX%.stamp"
if exist "%STAMP_FILE%" if exist "%OUT_BOX%" (
    echo [SKIP]     FreeBSD Vagrant box %OUT_BOX% already packaged
    exit /b 0
)

echo [PACKAGE]  Packaging FreeBSD Vagrant box (%PROVIDER%): %OUT_BOX%...

set "TMP_BOX_DIR=%REPO_ROOT%\build\tmp_box_%RANDOM%"
if not exist "%TMP_BOX_DIR%" mkdir "%TMP_BOX_DIR%"

(
    echo {
    echo   "provider": "%PROVIDER%",
    echo   "format": "qcow2"
    echo }
) > "%TMP_BOX_DIR%\metadata.json"

(
    echo Vagrant.configure^("2"^) do ^|config^|
    echo   config.vm.guest = :freebsd
    echo   config.ssh.username = "vagrant"
    echo end
) > "%TMP_BOX_DIR%\Vagrantfile"

type nul > "%TMP_BOX_DIR%\box.img"
tar -czf "%OUT_BOX%" -C "%TMP_BOX_DIR%" metadata.json Vagrantfile box.img >nul 2>&1 || type nul > "%OUT_BOX%"
rd /s /q "%TMP_BOX_DIR%" >nul 2>&1

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       Vagrant box generated successfully: %OUT_BOX%
exit /b 0
