@echo off
:: # audio.cmd
::
:: ## Overview
:: Configures audio subsystem (Boomer, OSS, or none) inside illumos sysroot
:: on Windows host environments.
::
:: ## Usage
:: audio.cmd [sysroot_path] [subsystem]

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
    echo Usage: %~nx0 [sysroot_path] [subsystem]
    echo Configures illumos audio subsystem.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [subsystem]
    echo Configures illumos audio subsystem.
    exit /b 0
)

set "REPO_ROOT=!SCRIPT_DIR!..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "SUBSYSTEM=%~2"
if "%SUBSYSTEM%"=="" set "SUBSYSTEM=none"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\audio.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos audio subsystem %SUBSYSTEM% already configured in %SYSROOT%
    exit /b 0
)

echo [AUDIO]    Configuring illumos audio subsystem %SUBSYSTEM%...

echo AUDIO_SUBSYSTEM="%SUBSYSTEM%"> "%SYSROOT%/etc/audio.conf"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos audio configuration complete.
exit /b 0
