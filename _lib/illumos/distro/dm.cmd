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

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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
    echo Usage: %~nx0 [sysroot_path] [display_manager] [autologin_user]
    echo Configures illumos display manager.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [display_manager] [autologin_user]
    echo Configures illumos display manager.
    exit /b 0
)

set "REPO_ROOT=!SCRIPT_DIR!\..\..\.."
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
