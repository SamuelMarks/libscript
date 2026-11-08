@echo off
:: # mount.cmd
:: ## Overview
:: Idempotently formats unformatted disks via _lib\storage\format_fs.cmd, supports --auto-data-disk discovery, and mounts volumes on Windows.
:: ## Usage
:: traits\storage\mount.cmd <device_or_disk|--auto-data-disk> <mount_point> [fstype]

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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

if /i "%~1"=="--auto-data-disk" (
    set "DEVICE=auto"
    set "MOUNT_POINT=%~2"
    if "!MOUNT_POINT!"=="" set "MOUNT_POINT=%DATA_DISK_MOUNT%"
    if "!MOUNT_POINT!"=="" set "MOUNT_POINT=%DATA_MOUNT_DIR%"
    if "!MOUNT_POINT!"=="" set "MOUNT_POINT=/mnt/data"
    set "FSTYPE=%~3"
) else (
    set "DEVICE=%~1"
    set "MOUNT_POINT=%~2"
    set "FSTYPE=%~3"
)
if "%FSTYPE%"=="" set "FSTYPE=ntfs"

if "%DEVICE%"=="" goto :help_err
if "%MOUNT_POINT%"=="" goto :help_err

if not exist "%MOUNT_POINT%" mkdir "%MOUNT_POINT%"
call :restore_ollama_models_ownership "%MOUNT_POINT%"
call :restore_service_data_ownership "%MOUNT_POINT%"
echo [INFO] Storage trait applied for %DEVICE% -^> %MOUNT_POINT% (%FSTYPE%).
exit /b 0

:: ## restore_service_data_ownership
:: Preserves and restores service ACLs on postgres, valkey, and redis directories inside the mounted volume on Windows.
:restore_service_data_ownership
set "_RSDO_BASE=%~1"
if not "!_RSDO_BASE!"=="" (
    for %%S in (postgres postgresql valkey redis) do (
        if exist "!_RSDO_BASE!\%%S" (
            icacls "!_RSDO_BASE!\%%S" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
        )
    )
)
if defined POSTGRES_DATA_DIR (
    if exist "!POSTGRES_DATA_DIR!" (
        icacls "!POSTGRES_DATA_DIR!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
    )
)
if defined PGDATA (
    if exist "!PGDATA!" (
        icacls "!PGDATA!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
    )
)
if defined VALKEY_DATA_DIR (
    if exist "!VALKEY_DATA_DIR!" (
        icacls "!VALKEY_DATA_DIR!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
    )
)
if defined REDIS_DATA_DIR (
    if exist "!REDIS_DATA_DIR!" (
        icacls "!REDIS_DATA_DIR!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
    )
)
exit /b 0

:: ## restore_ollama_models_ownership
:: Preserves and restores read/write permissions on the ollama_models directory inside the mounted volume on Windows.
:restore_ollama_models_ownership
set "_ROMO_BASE=%~1"
if not "!_ROMO_BASE!"=="" (
    if exist "!_ROMO_BASE!\ollama_models" (
        icacls "!_ROMO_BASE!\ollama_models" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
    )
)
if defined OLLAMA_MODELS_DIR (
    if exist "!OLLAMA_MODELS_DIR!" (
        icacls "!OLLAMA_MODELS_DIR!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
    )
)
if defined OLLAMA_MODELS (
    if exist "!OLLAMA_MODELS!" (
        icacls "!OLLAMA_MODELS!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
    )
)
exit /b 0

:: ## help
:: Prints usage help for mount.cmd.
:help
echo Usage: mount.cmd ^<device_or_disk^|--auto-data-disk^> ^<mount_point^> [fstype]
exit /b 0

:: ## help_err
:: Prints usage help and exits with code 1.
:help_err
echo Usage: mount.cmd ^<device_or_disk^|--auto-data-disk^> ^<mount_point^> [fstype] 1>&2
exit /b 1
