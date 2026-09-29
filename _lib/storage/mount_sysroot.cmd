@echo off
set "THIS_FILE=%~f0"
:: # mount_sysroot.cmd
::
:: ## Overview
:: Target storage mount manager for Windows environments.
:: Mounts virtual hard disks (VHD/VHDX), assigns target drive letters, and manages mount lifecycles.
::
:: ## Usage
:: Call mount_sysroot.cmd [--mount <vhd_or_volume> [drive_letter] | --unmount <vhd_or_volume>]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and command-line options.
:show_help
echo Usage: %~nx0 [--mount ^<vhd_path^> [drive_letter] ^| --unmount ^<vhd_path^>]
echo.
echo Mounts and unmounts target virtual storage on Windows.
echo.
echo Options:
echo   --mount ^<path^> [drive]  Mounts virtual hard disk image and assigns drive letter.
echo   --unmount ^<path^>        Dismounts virtual hard disk image.
echo   --help, -h, /?, -?      Show this help message and exit.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "ACTION=%~1"
set "TARGET_PATH=%~2"
set "DRIVE_LETTER=%~3"

if /i "%ACTION%"=="--mount" goto :do_mount
if /i "%ACTION%"=="--unmount" goto :do_unmount

echo [ERROR] Invalid action specified. Use --help for options. >&2
exit /b 1

:: ## do_mount
:: Mounts a VHD or VHDX file.
:do_mount
if "%TARGET_PATH%"=="" (
    echo [ERROR] Target VHD path required for --mount >&2
    exit /b 1
)
echo [INFO] Mounting virtual disk %TARGET_PATH%...
powershell -NoProfile -Command ^
    "$vhd = Mount-VHD -Path '%TARGET_PATH%' -Passthru; " ^
    "if ('%DRIVE_LETTER%' -ne '') { " ^
    "    Get-Disk -Number $vhd.DiskNumber | Get-Partition | Set-Partition -NewDriveLetter '%DRIVE_LETTER:~0,1%' " ^
    "}"

if !errorlevel! EQU 0 (
    echo [OK] Target disk %TARGET_PATH% mounted.
    exit /b 0
) else (
    echo [ERROR] Failed to mount %TARGET_PATH%. >&2
    exit /b 1
)

:: ## do_unmount
:: Dismounts a VHD or VHDX file.
:do_unmount
if "%TARGET_PATH%"=="" (
    echo [ERROR] Target VHD path required for --unmount >&2
    exit /b 1
)
echo [INFO] Dismounting virtual disk %TARGET_PATH%...
powershell -NoProfile -Command "Dismount-VHD -Path '%TARGET_PATH%'"
if !errorlevel! EQU 0 (
    echo [OK] Target disk %TARGET_PATH% dismounted.
    exit /b 0
) else (
    echo [ERROR] Failed to dismount %TARGET_PATH%. >&2
    exit /b 1
)
