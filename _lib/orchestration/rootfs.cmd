@echo off
:: # rootfs.cmd
::
:: ## Overview
:: Orchestrates rootfs staging for target operating system builds on Windows.
:: Initializes the FHS directory layout, default configuration skeletons,
:: and stamp tracking directories within the target sysroot.
::
:: ## Usage
:: Run `rootfs.cmd <target_sysroot> [--force]` to stage the target rootfs.

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


if "%~1"=="--help" (
    echo Usage: %~nx0 ^<target_sysroot^> [--force]
    echo Stages target rootfs tree and configuration files.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 ^<target_sysroot^> [--force]
    echo Stages target rootfs tree and configuration files.
    exit /b 0
)

set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" set "TARGET_DIR=%LIBSCRIPT_TARGET_SYSROOT%"
if "%TARGET_DIR%"=="" (
    echo [ERROR] Target sysroot directory required.
    echo Usage: %~nx0 ^<target_sysroot^> [--force]
    exit /b 1
)

set "FORCE=0"
if "%~2"=="--force" set "FORCE=1"

set "STAMP_DIR=%TARGET_DIR%\var\lib\libscript\stamps"
if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"

if "%FORCE%"=="0" (
    if exist "%STAMP_DIR%\.stamp.rootfs_staged" (
        echo [INFO] Target rootfs already staged at %TARGET_DIR%. Skipping.
        exit /b 0
    )
)

echo [INFO] Staging target rootfs at: %TARGET_DIR%


call "!SCRIPT_DIR!\create_fhs_layout.cmd" "%TARGET_DIR%"
if errorlevel 1 (
    echo [ERROR] create_fhs_layout failed.
    exit /b %ERRORLEVEL%
)

type nul > "%STAMP_DIR%\.stamp.rootfs_staged"
echo [INFO] Rootfs staging completed successfully: %TARGET_DIR%
exit /b 0
