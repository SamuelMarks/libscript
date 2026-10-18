@echo off
:: # mount_sysroot.cmd
::
:: ## Overview
:: Hierarchical target mount manager and chroot sysroot preparation engine.
:: Mounts root filesystems, ESP partitions, and virtual filesystems (/dev, /proc, /sys)
:: under /mnt/target, and generates persistent /etc/fstab or /etc/vfstab tables.
::
:: ## Usage
:: Execute this script to mount or unmount target sysroot:
::   ./_lib/storage/mount_sysroot.cmd [--mount <root_dev> [esp_dev] | --unmount | --fstab <target_dir>]

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
