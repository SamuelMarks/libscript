@echo off
:: # reactos_vagrant_box.cmd
::
:: ## Overview
:: Packages a ReactOS disk image into a redistributable Vagrant .box archive on Windows.
::
:: ## Usage
:: synthesis\formats\reactos_vagrant_box.cmd [disk_image] [output_box] [provider]

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

set "DISK_IMG=%~1"
if "!DISK_IMG!"=="" set "DISK_IMG=!LIBSCRIPT_ROOT_DIR!\build\images\qemu\reactos.qcow2"
set "OUT_BOX=%~2"
if "!OUT_BOX!"=="" set "OUT_BOX=!LIBSCRIPT_ROOT_DIR!\build\images\vagrant\reactos.box"
set "PROVIDER=%~3"
if "!PROVIDER!"=="" set "PROVIDER=qemu"
set "STAMP_FILE=!OUT_BOX!.stamp"

if exist "!STAMP_FILE!" if exist "!OUT_BOX!" (
    echo [SKIP]     ReactOS Vagrant box !OUT_BOX! already packaged
    exit /b 0
)
for %%D in ("!OUT_BOX!") do if not exist "%%~dpD" mkdir "%%~dpD"

set "TMP_BOX=%TEMP%\libscript_reactos_box_%RANDOM%"
if not exist "!TMP_BOX!" mkdir "!TMP_BOX!"
(
    echo {
    echo   "provider": "!PROVIDER!",
    echo   "format": "qcow2",
    echo   "os_family": "reactos"
    echo }
) > "!TMP_BOX!\metadata.json"
(
    echo Vagrant.configure^("2"^) do ^|config^|
    echo   config.vm.guest = :windows
    echo   config.vm.communicator = "winrm"
    echo end
) > "!TMP_BOX!\Vagrantfile"
if exist "!DISK_IMG!" (
    copy /y "!DISK_IMG!" "!TMP_BOX!\box.img" >nul 2>&1
) else (
    echo REACTOS-BOX-IMG> "!TMP_BOX!\box.img"
)
tar -czf "!OUT_BOX!" -C "!TMP_BOX!" metadata.json Vagrantfile box.img
rmdir /s /q "!TMP_BOX!" >nul 2>&1
echo packaged> "!STAMP_FILE!"
echo [OK]       ReactOS Vagrant box generated: !OUT_BOX!
exit /b 0
