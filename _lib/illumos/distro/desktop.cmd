@echo off
:: # desktop.cmd
::
:: ## Overview
:: Configures desktop environments (MATE, XFCE4, CDE, or none) inside illumos sysroot
:: on Windows host environments.
::
:: ## Usage
:: desktop.cmd [sysroot_path] [environment] [primary_user]

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
    echo Usage: %~nx0 [sysroot_path] [environment] [primary_user]
    echo Configures illumos desktop environment.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [environment] [primary_user]
    echo Configures illumos desktop environment.
    exit /b 0
)

set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "ENVIRONMENT=%~2"
if "%ENVIRONMENT%"=="" set "ENVIRONMENT=none"
set "PRIMARY_USER=%~3"
if "%PRIMARY_USER%"=="" set "PRIMARY_USER=vagrant"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\desktop.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"
if not exist "%SYSROOT%/export/home/%PRIMARY_USER%" mkdir "%SYSROOT%/export/home/%PRIMARY_USER%"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos desktop environment %ENVIRONMENT% already configured in %SYSROOT%
    exit /b 0
)

echo [DESKTOP]  Configuring illumos desktop environment %ENVIRONMENT% (user: %PRIMARY_USER%)...

if "%ENVIRONMENT%"=="mate" (
    echo exec mate-session> "%SYSROOT%/export/home/%PRIMARY_USER%/.xinitrc"
    echo DESKTOP_ENV="mate"> "%SYSROOT%/etc/desktop.conf"
) else if "%ENVIRONMENT%"=="xfce4" (
    echo exec startxfce4> "%SYSROOT%/export/home/%PRIMARY_USER%/.xinitrc"
    echo DESKTOP_ENV="xfce4"> "%SYSROOT%/etc/desktop.conf"
) else (
    echo DESKTOP_ENV="none"> "%SYSROOT%/etc/desktop.conf"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos desktop environment configuration complete.
exit /b 0
