@echo off
:: # api.cmd
::
:: ## Overview
:: API implementation for generating cloud-init YAML blocks for OS integration on Windows.
::
:: ## Usage
:: call "%~dp0api.cmd" :libscript_cloudinit_generate_mount /dev/sdf /data ext4

goto :%1

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
