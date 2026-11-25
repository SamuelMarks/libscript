@echo off
:: # dos_vagrant_box.cmd
::
:: ## Overview
:: Packages a synthesized DOS disk into a Vagrant .box archive on Windows.
::
:: ## Usage
:: synthesis\formats\dos_vagrant_box.cmd <sysroot_dir> <output.box>

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

set "_BSTG=%TEMP%\dos_vbox_!RANDOM!"
if not exist "!_BSTG!" mkdir "!_BSTG!"
for %%D in ("%~2") do if not exist "%%~dpD" mkdir "%%~dpD"
set "STACK="
call "!SCRIPT_DIR!\dos_qcow2.cmd" "%~1" "!_BSTG!\box.img"
if errorlevel 1 exit /b 1
echo {"provider":"qemu","format":"qcow2","virtual_size":1}> "!_BSTG!\metadata.json"
echo Vagrant.configure^("2"^) do ^|config^| end> "!_BSTG!\Vagrantfile"
tar -czf "%~2" -C "!_BSTG!" metadata.json Vagrantfile box.img
rmdir /s /q "!_BSTG!"
exit /b 0
