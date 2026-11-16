@echo off
:: # reactos_network_smoke_test.cmd
::
:: ## Overview
:: Network, DHCP, and service registration smoketest for ReactOS distributions on Windows.
::
:: ## Usage
:: tests\reactos_network_smoke_test.cmd [sysroot_path]

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

set "_TMP=%TEMP%\reactos_net_test_%RANDOM%"
set "LIBSCRIPT_HOME=!_TMP!\home"
set "LIBSCRIPT_OFFLINE=1"
set "LIBSCRIPT_ALLOW_STUB=1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\reactos\distro\assemble.cmd" "!LIBSCRIPT_ROOT_DIR!\profiles\reactos\developer-win32-i686.json" "!_TMP!\sys"
if errorlevel 1 exit /b 1
if not exist "!_TMP!\sys\iso_root\libscript\bootstrap\bin\curl.exe" exit /b 1
rmdir /s /q "!_TMP!" >nul 2>&1
echo [OK]       ReactOS network ^& service smoketest PASSED.
exit /b 0
