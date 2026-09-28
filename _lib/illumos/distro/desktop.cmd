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
    echo Usage: %~nx0 [sysroot_path] [environment] [primary_user]
    echo Configures illumos desktop environment.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [environment] [primary_user]
    echo Configures illumos desktop environment.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
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
