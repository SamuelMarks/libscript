@echo off
:: # audio.cmd
::
:: ## Overview
:: Configures the ReactOS WDM audio subsystem inside the target sysroot on Windows.
::
:: ## Usage
:: synthesis\distro\reactos\audio.cmd [sysroot_path] [subsystem]

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
set "AUDIO_SUB=%~2"
if "!AUDIO_SUB!"=="" set "AUDIO_SUB=none"

set "STAMP_DIR=!SYSROOT!\.libscript-stamps"
set "STAMP_FILE=!STAMP_DIR!\audio.stamp"
set "LS_STAGE=!SYSROOT!\iso_root\libscript"

if exist "!STAMP_FILE!" (
    echo [SKIP]     ReactOS audio subsystem ^(!AUDIO_SUB!^) already configured in !SYSROOT!
    exit /b 0
)
if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"
if not exist "!LS_STAGE!" mkdir "!LS_STAGE!"

echo audio=!AUDIO_SUB!> "!LS_STAGE!\audio.conf"
if /I not "!AUDIO_SUB!"=="none" (
    set "_SC=sc.exe"
    echo !_SC! config audiosrv start= auto ^>nul 2^>^&1>> "!LS_STAGE!\firstboot.cmd"
)

echo configured> "!STAMP_FILE!"
echo [OK]       ReactOS audio subsystem ^(!AUDIO_SUB!^) configured.
exit /b 0
