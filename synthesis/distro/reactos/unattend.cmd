@echo off
:: # unattend.cmd
::
:: ## Overview
:: Generates reactos\unattend.inf ([Unattend] + [GuiRunOnce]) inside the ReactOS ISO root on Windows.
::
:: ## Usage
:: synthesis\distro\reactos\unattend.cmd [sysroot_path] [computer_name] [admin_password] [locale_id] [tz_index] [fs_type]

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

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"
set "COMP_NAME=%~2"
if "!COMP_NAME!"=="" set "COMP_NAME=REACTOS-NODE"
set "ADMIN_PASS=%~3"
set "LOCALE_ID=%~4"
if "!LOCALE_ID!"=="" set "LOCALE_ID=00000409"
set "TZ_INDEX=%~5"
if "!TZ_INDEX!"=="" set "TZ_INDEX=85"
set "FS_TYPE=%~6"
if "!FS_TYPE!"=="" set "FS_TYPE=fat32"

set "STAMP_DIR=!SYSROOT!\.libscript-stamps"
set "STAMP_FILE=!STAMP_DIR!\unattend.stamp"
set "ISO_ROOT=!SYSROOT!\iso_root"

if exist "!STAMP_FILE!" if exist "!ISO_ROOT!\reactos\unattend.inf" (
    echo [SKIP]     ReactOS unattend.inf already generated in !SYSROOT!
    exit /b 0
)
if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"
if not exist "!ISO_ROOT!\reactos" mkdir "!ISO_ROOT!\reactos"

set "FS_CODE=1"
if /I "!FS_TYPE!"=="btrfs" set "FS_CODE=2"
if /I "!FS_TYPE!"=="ntfs" set "FS_CODE=3"

(
    echo [Version]
    echo Signature = "$ReactOS$"
    echo.
    echo [Unattend]
    echo Signature = "$ReactOS$"
    echo UnattendSetupEnabled = yes
    echo DestinationDiskNumber = 0
    echo DestinationPartitionNumber = 1
    echo InstallationDirectory = ReactOS
    echo MBRInstallType = 2
    echo FullName = "LibScript User"
    echo OrgName = "LibScript"
    echo ComputerName = !COMP_NAME!
    echo AdminPassword = !ADMIN_PASS!
    echo TimeZoneIndex = !TZ_INDEX!
    echo DisableAutoDaylightTimeSet = 1
    echo ConfirmHardware = no
    echo FormatPartition = 1
    echo AutoPartition = 1
    echo FileSystem = !FS_CODE!
    echo LocaleID = !LOCALE_ID!
    echo DisableGeckoInst = yes
    echo.
    echo [GuiRunOnce]
    echo %%SystemDrive%%\libscript\firstboot.cmd
) > "!ISO_ROOT!\reactos\unattend.inf"

echo generated> "!STAMP_FILE!"
echo [OK]       Generated reactos\unattend.inf ^(ComputerName=!COMP_NAME!^).
exit /b 0
