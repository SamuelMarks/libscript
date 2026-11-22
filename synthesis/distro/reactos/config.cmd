@echo off
:: # config.cmd
::
:: ## Overview
:: Initializes the ReactOS firstboot.cmd runner and registry delta file on Windows.
::
:: ## Usage
:: synthesis\distro\reactos\config.cmd [sysroot_path] [hostname] [dhcp] [dns_csv]

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
set "HOSTNAME_VAL=%~2"
if "!HOSTNAME_VAL!"=="" set "HOSTNAME_VAL=REACTOS-NODE"
set "USE_DHCP=%~3"
if "!USE_DHCP!"=="" set "USE_DHCP=true"
set "DNS_CSV=%~4"
if "!DNS_CSV!"=="" set "DNS_CSV=1.1.1.1,8.8.8.8"

set "STAMP_DIR=!SYSROOT!\.libscript-stamps"
set "STAMP_FILE=!STAMP_DIR!\config.stamp"
set "LS_STAGE=!SYSROOT!\iso_root\libscript"

if exist "!STAMP_FILE!" (
    echo [SKIP]     ReactOS core config already staged in !SYSROOT!
    exit /b 0
)
if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"
if not exist "!LS_STAGE!" mkdir "!LS_STAGE!"
if not exist "!SYSROOT!\iso_root\ReactOS\System32\drivers\etc" mkdir "!SYSROOT!\iso_root\ReactOS\System32\drivers\etc"

(
    echo 127.0.0.1       localhost
    echo 127.0.0.1       !HOSTNAME_VAL!
) > "!SYSROOT!\iso_root\ReactOS\System32\drivers\etc\hosts"

(
    echo Windows Registry Editor Version 5.00
    echo.
    echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName]
    echo "ComputerName"="!HOSTNAME_VAL!"
    echo.
    echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters]
    echo "Hostname"="!HOSTNAME_VAL!"
    echo "NameServer"="!DNS_CSV!"
) > "!LS_STAGE!\hivesft_delta.reg"

(
    echo @echo off
    echo setlocal EnableDelayedExpansion
    echo set "_SD=%%SystemDrive%%"
    echo if "^!_SD^!"=="" set "_SD=C:"
    echo if exist "^!_SD^!\libscript\.firstboot.done" exit /b 0
    echo set "PATH=^!_SD^!\libscript\bootstrap\bin;^!PATH^!"
    echo set "IS_REACTOS=1"
    echo set "LIBSCRIPT_OFFLINE=1"
    echo echo [LIBSCRIPT-FIRSTBOOT] Applying registry and network configuration...
    echo if exist "^!_SD^!\libscript\hivesft_delta.reg" reg.exe import "^!_SD^!\libscript\hivesft_delta.reg" ^>nul 2^>^&1
) > "!LS_STAGE!\firstboot.cmd"

echo configured> "!STAMP_FILE!"
echo [OK]       ReactOS core config ^& firstboot.cmd initialized ^(hostname=!HOSTNAME_VAL!^).
exit /b 0
