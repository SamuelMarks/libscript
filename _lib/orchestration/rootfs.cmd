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

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

call "%SCRIPT_DIR%\create_fhs_layout.cmd" "%TARGET_DIR%"
if errorlevel 1 (
    echo [ERROR] create_fhs_layout failed.
    exit /b %ERRORLEVEL%
)

type nul > "%STAMP_DIR%\.stamp.rootfs_staged"
echo [INFO] Rootfs staging completed successfully: %TARGET_DIR%
exit /b 0
