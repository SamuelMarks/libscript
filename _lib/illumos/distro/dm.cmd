@echo off
:: # dm.cmd
::
:: ## Overview
:: Configures display managers (LightDM, Slim, XDM, or none) inside illumos sysroot
:: on Windows host environments.
::
:: ## Usage
:: dm.cmd [sysroot_path] [display_manager] [autologin_user]

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
    echo Usage: %~nx0 [sysroot_path] [display_manager] [autologin_user]
    echo Configures illumos display manager.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [display_manager] [autologin_user]
    echo Configures illumos display manager.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "DM=%~2"
if "%DM%"=="" set "DM=none"
set "AUTOLOGIN_USER=%~3"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\dm.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos display manager %DM% already configured in %SYSROOT%
    exit /b 0
)

echo [DM]       Configuring illumos display manager %DM%...

if "%DM%"=="lightdm" (
    if not exist "%SYSROOT%/etc/lightdm" mkdir "%SYSROOT%/etc/lightdm"
    (
        echo [Seat:*]
        echo greeter-session=lightdm-gtk-greeter
    ) > "%SYSROOT%/etc/lightdm/lightdm.conf"
    echo DISPLAY_MANAGER="lightdm"> "%SYSROOT%/etc/dm.conf"
) else (
    echo DISPLAY_MANAGER="none"> "%SYSROOT%/etc/dm.conf"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos display manager configuration complete.
exit /b 0
