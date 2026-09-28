@echo off
:: # pkg.cmd
::
:: ## Overview
:: Configures illumos package managers (IPS pkg(1), pkgin, or zap)
:: on Windows host environments.
::
:: ## Usage
:: pkg.cmd [sysroot_path] [provider] [publisher_url]

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
    echo Usage: %~nx0 [sysroot_path] [provider] [publisher_url]
    echo Configures illumos package publisher.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [provider] [publisher_url]
    echo Configures illumos package publisher.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "PROVIDER=%~2"
if "%PROVIDER%"=="" set "PROVIDER=ips"
set "PUB_URL=%~3"
if "%PUB_URL%"=="" set "PUB_URL=https://pkg.omnios.org/r151048/core"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\pkg.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos package manager already configured in %SYSROOT%
    exit /b 0
)

echo [PKG]      Configuring illumos package manager (%PROVIDER%, publisher: %PUB_URL%)...

if "%PROVIDER%"=="ips" (
    if not exist "%SYSROOT%\var\pkg" mkdir "%SYSROOT%\var\pkg"
    if not exist "%SYSROOT%\etc\pkg" mkdir "%SYSROOT%\etc\pkg"
    (
        echo # IPS Package Publisher Configuration (managed by LibScript^)
        echo [publisher]
        echo prefix = omnios
        echo uri = %PUB_URL%
        echo sticky = true
        echo enabled = true
    ) > "%SYSROOT%\etc\pkg\publishers.conf"
) else if "%PROVIDER%"=="pkgin" (
    if not exist "%SYSROOT%\opt\local\etc\pkgin" mkdir "%SYSROOT%\opt\local\etc\pkgin"
    echo %PUB_URL%> "%SYSROOT%\opt\local\etc\pkgin/repositories.conf"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos package manager configuration complete.
exit /b 0
