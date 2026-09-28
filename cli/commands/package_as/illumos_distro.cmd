@echo off
:: # illumos_distro.cmd
::
:: ## Overview
:: Unified CLI entrypoint to package an illumos distribution profile into
:: raw, qcow2, vagrant box, vhd, vmdk, or iso target formats on Windows.
::
:: ## Usage
:: illumos_distro.cmd --format <qcow2|box|raw|vhd|vmdk|iso> --profile <profile_json> [--output <path>]

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
    echo Usage: %~nx0 --format [qcow2^|box^|raw^|vhd^|vmdk^|iso] --profile [path]
    echo Packages illumos distribution from profile.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 --format [qcow2^|box^|raw^|vhd^|vmdk^|iso] --profile [path]
    echo Packages illumos distribution from profile.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "FORMAT=qcow2"
set "PROFILE=%REPO_ROOT%\profiles\illumos\minimal-server.json"
set "OUTPUT="

:parse_loop
if "%~1"=="" goto parse_done
if /I "%~1"=="--format" (
    set "FORMAT=%~2"
    shift
    shift
    goto parse_loop
)
if /I "%~1"=="-f" (
    set "FORMAT=%~2"
    shift
    shift
    goto parse_loop
)
if /I "%~1"=="--profile" (
    set "PROFILE=%~2"
    shift
    shift
    goto parse_loop
)
if /I "%~1"=="-p" (
    set "PROFILE=%~2"
    shift
    shift
    goto parse_loop
)
if /I "%~1"=="--output" (
    set "OUTPUT=%~2"
    shift
    shift
    goto parse_loop
)
if /I "%~1"=="-o" (
    set "OUTPUT=%~2"
    shift
    shift
    goto parse_loop
)
shift
goto parse_loop
:parse_done

set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"

echo [DISTRO]   Synthesizing illumos sysroot from %PROFILE%...
call "%REPO_ROOT%\_lib\illumos\distro\assemble.cmd" "%PROFILE%" "%SYSROOT%"

if "%FORMAT%"=="qcow2" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\illumos.qcow2"
    call "%SCRIPT_DIR%illumos_qcow2.cmd" "%SYSROOT%" "%OUTPUT%" 20
) else if "%FORMAT%"=="box" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\illumos.box"
    set "QCOW_TMP=%REPO_ROOT%\build\illumos.qcow2"
    call "%SCRIPT_DIR%illumos_qcow2.cmd" "%SYSROOT%" "%QCOW_TMP%" 20
    call "%SCRIPT_DIR%illumos_vagrant_box.cmd" "%QCOW_TMP%" "%OUTPUT%" "qemu"
) else if "%FORMAT%"=="raw" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\illumos.raw"
    call "%SCRIPT_DIR%illumos_raw.cmd" "%SYSROOT%" "%OUTPUT%" 20
) else if "%FORMAT%"=="vhd" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\illumos.vhd"
    call "%SCRIPT_DIR%illumos_vhd.cmd" "%SYSROOT%" "%OUTPUT%" 20
) else if "%FORMAT%"=="vmdk" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\illumos.vmdk"
    call "%SCRIPT_DIR%illumos_vmdk.cmd" "%SYSROOT%" "%OUTPUT%" 20
) else if "%FORMAT%"=="iso" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\illumos.iso"
    call "%SCRIPT_DIR%illumos_iso.cmd" "%SYSROOT%" "%OUTPUT%"
)

echo [OK]       Packaging complete: %OUTPUT%
exit /b 0
