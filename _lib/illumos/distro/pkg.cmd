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
