@echo off
:: # display.cmd
::
:: ## Overview
:: Configures display subsystem (X11 Xorg server or headless) inside illumos sysroot
:: on Windows host environments.
::
:: ## Usage
:: display.cmd [sysroot_path] [protocol] [driver]

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
    echo Usage: %~nx0 [sysroot_path] [protocol] [driver]
    echo Configures illumos display subsystem.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [protocol] [driver]
    echo Configures illumos display subsystem.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "PROTOCOL=%~2"
if "%PROTOCOL%"=="" set "PROTOCOL=none"
set "DRIVER=%~3"
if "%DRIVER%"=="" set "DRIVER=none"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\display.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos display protocol %PROTOCOL% already configured in %SYSROOT%
    exit /b 0
)

echo [DISPLAY]  Configuring illumos display protocol %PROTOCOL% (driver: %DRIVER%)...

if "%PROTOCOL%"=="x11" (
    if not exist "%SYSROOT%/etc/X11" mkdir "%SYSROOT%/etc/X11"
    echo DISPLAY_MODE="x11"> "%SYSROOT%/etc/display.conf"
) else (
    echo DISPLAY_MODE="headless"> "%SYSROOT%/etc/display.conf"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos display configuration complete.
exit /b 0
