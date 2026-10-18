@echo off
:: # nfs.cmd
::
:: ## Overview
:: Idempotently mounts NFSv4 or GCP Filestore exports on Windows.
::
:: ## Usage
:: traits\storage\nfs.cmd <nfs_server_export> <drive_or_mount>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

set "NFS_EXPORT=%~1"
set "MOUNT_POINT=%~2"

if "%NFS_EXPORT%"=="" goto :help_err
if "%MOUNT_POINT%"=="" goto :help_err

if exist "%MOUNT_POINT%" (
    echo [INFO] NFS mount point %MOUNT_POINT% is already accessible.
    exit /b 0
)

echo [INFO] Mounting NFS export %NFS_EXPORT% at %MOUNT_POINT%...
mount -o anon "%NFS_EXPORT%" "%MOUNT_POINT%" >nul 2>&1
exit /b 0

:: ## help
:: Prints usage help for nfs.cmd.
:help
echo Usage: nfs.cmd ^<nfs_server_export^> ^<drive_or_mount^>
exit /b 0

:: ## help_err
:: Prints usage help and exits with code 1.
:help_err
echo Usage: nfs.cmd ^<nfs_server_export^> ^<drive_or_mount^> 1>&2
exit /b 1
