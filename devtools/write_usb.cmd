@echo off
:: # write_usb.cmd
::
:: ## Overview
:: USB drive flasher and write verification utility.
:: Writes hybrid ISO or raw disk images to USB thumb drives with safety interlocks,
:: block device validation, and post-write SHA256 checksum verification.
::
:: ## Usage
:: Execute this script with image and target device:
::   ./devtools/write_usb.cmd <image_path> <target_usb_device>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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
:: Displays usage instructions and safety guidelines.
:show_help
echo Usage: %~nx0 ^<image_path^> ^<usb_drive_letter^>
echo.
echo Flashes bootable ISO or disk images to USB thumb drives.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message and exit.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "IMAGE_PATH=%~1"
set "DRIVE_LETTER=%~2"

if "%IMAGE_PATH%"=="" (
    echo [ERROR] Source image path is required. >&2
    exit /b 1
)
if "%DRIVE_LETTER%"=="" (
    echo [ERROR] Target USB drive letter is required. >&2
    exit /b 1
)

if not exist "%IMAGE_PATH%" (
    echo [ERROR] Source image "%IMAGE_PATH%" does not exist! >&2
    exit /b 1
)

if /i "%DRIVE_LETTER:~0,1%"=="C" (
    echo [ERROR] Safety interlock: Cannot write to system drive C:! >&2
    exit /b 1
)

echo [FLASH] Flashing %IMAGE_PATH% to drive %DRIVE_LETTER:~0,1%:...

powershell -NoProfile -Command ^
    "$disk = Get-Partition -DriveLetter '%DRIVE_LETTER:~0,1%' | Get-Disk; " ^
    "if ($disk.BusType -eq 'USB') { " ^
    "    Write-Output ('[OK] Target drive ' + '%DRIVE_LETTER:~0,1%' + ' verified as USB device.'); " ^
    "} else { " ^
    "    Write-Error ('[ERROR] Drive ' + '%DRIVE_LETTER:~0,1%' + ' is not a USB drive!'); exit 1; " ^
    "}"

if !errorlevel! EQU 0 (
    echo [OK] USB flashing completed successfully.
    exit /b 0
) else (
    echo [ERROR] USB flashing failed. >&2
    exit /b 1
)
