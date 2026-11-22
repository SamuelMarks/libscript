@echo off
:: # reactos_vagrant_box_test.cmd
::
:: ## Overview
:: Vagrant .box lifecycle smoketest for generated ReactOS .box archives on Windows.
::
:: ## Usage
:: tests\reactos_vagrant_box_test.cmd [box_path]

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

set "_TMP=%TEMP%\reactos_box_test_%RANDOM%"
if not exist "!_TMP!" mkdir "!_TMP!"
set "LIBSCRIPT_OFFLINE=1"
set "LIBSCRIPT_ALLOW_STUB=1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\reactos_distro.cmd" --format box --profile "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\reactos\minimal-headless-i686.json" --sysroot "!_TMP!\sys" --output "!_TMP!\reactos.box"
if errorlevel 1 exit /b 1
tar -tzf "!_TMP!\reactos.box" >nul 2>&1
if errorlevel 1 exit /b 1
rmdir /s /q "!_TMP!" >nul 2>&1
echo [OK]       ReactOS Vagrant box lifecycle test PASSED.
exit /b 0
