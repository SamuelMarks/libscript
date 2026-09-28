@echo off
:: # pkg.cmd
::
:: ## Overview
:: Configures pkg(8) package manager configuration and repository mirrors
:: for the target FreeBSD sysroot on Windows environments.
::
:: ## Usage
:: pkg.cmd [sysroot_path] [branch]

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
    echo Usage: %~nx0 [sysroot_path] [branch]
    echo Configures FreeBSD pkg package repository.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [branch]
    echo Configures FreeBSD pkg package repository.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"
set "BRANCH=%~2"
if "%BRANCH%"=="" set "BRANCH=quarterly"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\pkg.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\usr\local\etc\pkg
epos" mkdir "%SYSROOT%\usr\local\etc\pkg
epos"
if not exist "%SYSROOT%\var\db\pkg" mkdir "%SYSROOT%\var\db\pkg"
if not exist "%SYSROOT%\var\cache\pkg" mkdir "%SYSROOT%\var\cache\pkg"

if exist "%STAMP_FILE%" (
    echo [SKIP]     FreeBSD pkg repository already configured in %SYSROOT%
    exit /b 0
)

echo [PKG]      Configuring FreeBSD pkg repository (%BRANCH% branch)...

(
    echo FreeBSD: {
    echo   url: "pkg+http://pkg.FreeBSD.org/${ABI}/%BRANCH%",
    echo   mirror_type: "srv",
    echo   signature_type: "fingerprints",
    echo   fingerprints: "/usr/share/keys/pkg",
    echo   enabled: yes
    echo }
) > "%SYSROOT%\usr\local\etc\pkg
epos\FreeBSD.conf"

(
    echo PKG_DBDIR = "/var/db/pkg";
    echo PKG_CACHEDIR = "/var/cache/pkg";
    echo PORTSDIR = "/usr/ports";
    echo REPO_AUTOUPDATE = YES;
) > "%SYSROOT%\usr\local\etc\pkg.conf"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       FreeBSD pkg configuration complete.
exit /b 0
