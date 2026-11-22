@echo off
:: # desktop.cmd
::
:: ## Overview
:: Configures the ReactOS Winlogon user shell and visual style theme on Windows.
::
:: ## Usage
:: synthesis\distro\reactos\desktop.cmd [sysroot_path] [shell] [theme] [custom_shell_path]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
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

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"
set "SHELL_MODE=%~2"
if "!SHELL_MODE!"=="" set "SHELL_MODE=explorer-classic"
set "THEME_NAME=%~3"
if "!THEME_NAME!"=="" set "THEME_NAME=classic"
set "CUSTOM_SHELL=%~4"

set "STAMP_DIR=!SYSROOT!\.libscript-stamps"
set "STAMP_FILE=!STAMP_DIR!\desktop.stamp"
set "LS_STAGE=!SYSROOT!\iso_root\libscript"
set "THEMES_DIR=!SYSROOT!\iso_root\ReactOS\Resources\Themes\!THEME_NAME!"

if exist "!STAMP_FILE!" (
    echo [SKIP]     ReactOS desktop shell ^(!SHELL_MODE!^) already configured in !SYSROOT!
    exit /b 0
)
if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"
if not exist "!LS_STAGE!" mkdir "!LS_STAGE!"
if not exist "!THEMES_DIR!" mkdir "!THEMES_DIR!"

set "_SH_BIN=explorer.exe"
if /I "!SHELL_MODE!"=="cmd-minimal" set "_SH_BIN=cmd.exe"
if /I "!SHELL_MODE!"=="custom" if not "!CUSTOM_SHELL!"=="" set "_SH_BIN=!CUSTOM_SHELL!"

(
    echo shell=!SHELL_MODE!
    echo executable=!_SH_BIN!
    echo theme=!THEME_NAME!
) > "!LS_STAGE!\desktop.conf"

if /I not "!THEME_NAME!"=="classic" echo MSSTYLES-REACTOS-!THEME_NAME!> "!THEMES_DIR!\!THEME_NAME!.msstyles"

(
    echo.
    echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
    echo "Shell"="!_SH_BIN!"
) >> "!LS_STAGE!\hivesft_delta.reg"

echo configured> "!STAMP_FILE!"
echo [OK]       ReactOS desktop shell ^(!SHELL_MODE! -^> !_SH_BIN!, theme=!THEME_NAME!^) configured.
exit /b 0
