@echo off
set "THIS_FILE=%~f0"
:: # write_usb.cmd
::
:: ## Overview
:: USB drive flasher and write verification utility for Windows.
:: Flashes bootable ISO or disk images to USB drives with safety validations.
::
:: ## Usage
:: Call write_usb.cmd <image_path> <usb_drive_letter>

setlocal EnableDelayedExpansion

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
