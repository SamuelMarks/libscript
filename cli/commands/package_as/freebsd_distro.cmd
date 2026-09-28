@echo off
:: # freebsd_distro.cmd
::
:: ## Overview
:: Unified CLI entrypoint to package a FreeBSD distribution profile on Windows.
::
:: ## Usage
:: freebsd_distro.cmd --format <qcow2|box|raw|vhd|vmdk|iso> --profile <profile_json>

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
    echo Packages FreeBSD distribution profile.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 --format [qcow2^|box^|raw^|vhd^|vmdk^|iso] --profile [path]
    echo Packages FreeBSD distribution profile.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "FORMAT=qcow2"
set "PROFILE=%REPO_ROOT%\profiles\freebsd\minimal-server.json"
set "OUTPUT="

:parse_loop
if "%~1"=="" goto after_parse
if "%~1"=="--format" (
    set "FORMAT=%~2"
    shift
    shift
    goto parse_loop
)
if "%~1"=="-f" (
    set "FORMAT=%~2"
    shift
    shift
    goto parse_loop
)
if "%~1"=="--profile" (
    set "PROFILE=%~2"
    shift
    shift
    goto parse_loop
)
if "%~1"=="-p" (
    set "PROFILE=%~2"
    shift
    shift
    goto parse_loop
)
if "%~1"=="--output" (
    set "OUTPUT=%~2"
    shift
    shift
    goto parse_loop
)
if "%~1"=="-o" (
    set "OUTPUT=%~2"
    shift
    shift
    goto parse_loop
)
shift
goto parse_loop

:after_parse
set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"

echo [DISTRO]   Synthesizing FreeBSD sysroot from %PROFILE%...
call "%REPO_ROOT%\_lib\freebsd\distro\assemble.cmd" "%PROFILE%" "%SYSROOT%"

if "%FORMAT%"=="raw" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\freebsd.raw"
    call "%SCRIPT_DIR%freebsd_raw.cmd" "%SYSROOT%" "!OUTPUT!" 20
)
if "%FORMAT%"=="qcow2" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\freebsd.qcow2"
    call "%SCRIPT_DIR%freebsd_qcow2.cmd" "%SYSROOT%" "!OUTPUT!" 20
)
if "%FORMAT%"=="box" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\freebsd.box"
    set "QCOW_TMP=%REPO_ROOT%\build\freebsd.qcow2"
    call "%SCRIPT_DIR%freebsd_qcow2.cmd" "%SYSROOT%" "!QCOW_TMP!" 20
    call "%SCRIPT_DIR%freebsd_vagrant_box.cmd" "!QCOW_TMP!" "!OUTPUT!" "qemu"
)
if "%FORMAT%"=="vhd" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\freebsd.vhd"
    call "%SCRIPT_DIR%freebsd_vhd.cmd" "%SYSROOT%" "!OUTPUT!" 20
)
if "%FORMAT%"=="vmdk" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\freebsd.vmdk"
    call "%SCRIPT_DIR%freebsd_vmdk.cmd" "%SYSROOT%" "!OUTPUT!" 20
)
if "%FORMAT%"=="iso" (
    if "%OUTPUT%"=="" set "OUTPUT=%REPO_ROOT%\build\freebsd.iso"
    call "%SCRIPT_DIR%freebsd_iso.cmd" "%SYSROOT%" "!OUTPUT!"
)

echo [OK]       FreeBSD distribution packaged successfully as %FORMAT%: %OUTPUT%
exit /b 0
