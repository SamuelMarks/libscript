@echo off
set "THIS_FILE=%~f0"
:: # format.cmd
::
:: ## Overview
:: Filesystem formatting engine for Windows environments.
:: Formats volumes as FAT32, NTFS, or ReFS with label assignment and idempotency verification.
::
:: ## Usage
:: Call format.cmd <drive_letter_or_number> [fs_type] [volume_label]

setlocal EnableDelayedExpansion

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
