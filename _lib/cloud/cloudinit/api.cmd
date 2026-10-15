@echo off
:: # api.cmd
::
:: ## Overview
:: API implementation for generating cloud-init YAML blocks for OS integration on Windows.
::
:: ## Usage
:: call "%~dp0api.cmd" :libscript_cloudinit_generate_mount /dev/sdf /data ext4
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

goto :%1

:: ## libscript_cloudinit_generate_mount
:: Performs the libscript_cloudinit_generate_mount operation and updates component state.
:libscript_cloudinit_generate_mount
set "device=%~2"
set "mount_point=%~3"
set "fs_type=%~4"

if "%device%"=="" (
    echo Error: device and mount_point are required parameters. >&2
    exit /b 1
)
if "%mount_point%"=="" (
    echo Error: device and mount_point are required parameters. >&2
    exit /b 1
)
if "%fs_type%"=="" set "fs_type=ext4"

echo #cloud-config
echo.
echo bootcmd:
echo   - mkdir -p %mount_point%
echo.
echo disk_setup:
echo   %device%:
echo     table_type: mbr
echo     layout: true
echo     overwrite: false
echo.
echo fs_setup:
echo   - label: data_vol
echo     filesystem: %fs_type%
echo     device: %device%1
echo.
echo mounts:
echo   - [ %device%1, %mount_point%, %fs_type%, "defaults,nofail,discard", "0", "2" ]

exit /b 0
