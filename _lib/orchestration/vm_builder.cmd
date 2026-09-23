@echo off
:: # vm_builder.cmd
::
:: ## Overview
:: Cross-platform kernel virtualization bridge on Windows.
:: Delegates Linux kernel-dependent operations (loopback partitioning, mkfs, VFS mount)
:: to a lightweight Alpine Linux worker running in Docker or WSL2.
::
:: ## Usage
:: Run `vm_builder.cmd [--worker=docker|wsl2] <command...>` to execute inside worker.

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
    echo Usage: %~nx0 [--worker=docker^|wsl2] ^<command...^>
    echo Delegates kernel-dependent operations to Docker or WSL2 worker.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [--worker=docker^|wsl2] ^<command...^>
    echo Delegates kernel-dependent operations to Docker or WSL2 worker.
    exit /b 0
)

set "WORKER_TYPE=auto"
set "CMD_ARGS="

:parse_loop
if "%~1"=="" goto after_parse
set "arg=%~1"
if "!arg:~0,9!"=="--worker=" (
    set "WORKER_TYPE=!arg:~9!"
    shift
    goto parse_loop
)
set "CMD_ARGS=%*"
goto after_parse

:after_parse
if "%CMD_ARGS%"=="" (
    echo [ERROR] No command specified for vm_builder.
    echo Usage: %~nx0 [--worker=docker^|wsl2] ^<command...^>
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%\..\..") do set "REPO_ROOT=%%~fI"

if "%WORKER_TYPE%"=="auto" (
    docker --version >nul 2>&1
    if !errorlevel! equ 0 (
        set "WORKER_TYPE=docker"
    ) else (
        wsl.exe --status >nul 2>&1
        if !errorlevel! equ 0 (
            set "WORKER_TYPE=wsl2"
        ) else (
            echo [ERROR] No supported virtualization backend (docker, wsl2) detected on Windows.
            exit /b 86
        )
    )
)

echo [INFO] Executing via virtualization bridge (worker: %WORKER_TYPE%)...

if "%WORKER_TYPE%"=="docker" (
    docker run --rm --privileged -v "%REPO_ROOT%:/workspace" -w /workspace -e LIBSCRIPT_TARGET_SYSROOT="%LIBSCRIPT_TARGET_SYSROOT%" -e LIBSCRIPT_OFFLINE="%LIBSCRIPT_OFFLINE%" alpine:latest sh -c "apk add --no-cache bash coreutils util-linux parted e2fsprogs btrfs-progs xfsprogs dosfstools cryptsetup findmnt udev >/dev/null 2>&1 || true; %CMD_ARGS%"
    exit /b !errorlevel!
)

if "%WORKER_TYPE%"=="wsl2" (
    wsl.exe --cd "%REPO_ROOT%" -- /bin/sh -c "%CMD_ARGS%"
    exit /b !errorlevel!
)

echo [ERROR] Unsupported worker type: %WORKER_TYPE%
exit /b 1
