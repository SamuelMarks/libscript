@echo off
:: # format.cmd
::
:: ## Overview
:: Unified filesystem formatter and OpenZFS root pool initialization engine.
:: Prepares EFI System Partitions (FAT32), Linux root filesystems (ext4/xfs/btrfs),
:: FreeBSD UFS2 partitions, and canonical OpenZFS root pools with structured datasets.
::
:: ## Usage
:: Execute this script to format a block partition or initialize a ZFS pool:
::   ./_lib/storage/format.cmd <device_or_slice> [fs_type] [pool_name]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
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



if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and command-line options.
:show_help
echo Usage: %~nx0 ^<drive_letter_or_number^> [fs_type] [volume_label]
echo.
echo Formats storage partitions on Windows.
echo.
echo Filesystem Types:
echo   ntfs      - New Technology File System (default)
echo   fat32     - FAT32 for EFI ESP or boot partitions
echo   refs      - Resilient File System
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "TARGET_VOL=%~1"
set "FS_TYPE=%~2"
set "VOL_LABEL=%~3"

if "%TARGET_VOL%"==" " set "TARGET_VOL="
if "%TARGET_VOL%"=="" (
    echo [ERROR] Target drive letter or partition identifier is required. >&2
    exit /b 1
)
if "%FS_TYPE%"=="" set "FS_TYPE=NTFS"
if "%VOL_LABEL%"=="" set "VOL_LABEL=LibScriptTarget"

echo [INFO] Formatting %TARGET_VOL% as %FS_TYPE% (%VOL_LABEL%)...

powershell -NoProfile -Command ^
    "$vol = Get-Volume -DriveLetter '%TARGET_VOL:~0,1%' -ErrorAction SilentlyContinue; " ^
    "if ($vol -and $vol.FileSystem -eq '%FS_TYPE%') { " ^
    "    Write-Output '[INFO] Volume %TARGET_VOL% already formatted as %FS_TYPE%. Preserving.'; " ^
    "} else { " ^
    "    Format-Volume -DriveLetter '%TARGET_VOL:~0,1%' -FileSystem %FS_TYPE% -NewFileSystemLabel '%VOL_LABEL%' -Confirm:$false; " ^
    "}"

if !errorlevel! EQU 0 (
    echo [OK] Formatting of %TARGET_VOL% as %FS_TYPE% completed successfully.
    exit /b 0
) else (
    echo [ERROR] Failed to format volume %TARGET_VOL%. >&2
    exit /b 1
)
