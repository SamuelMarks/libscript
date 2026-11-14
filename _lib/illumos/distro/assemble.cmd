@echo off
:: # assemble.cmd
:: ## Overview
:: Orchestrates illumos distribution synthesis from a JSON profile specification using jq on Windows.
:: ## Usage
:: assemble.cmd [profile_json_path] [target_sysroot]

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help

set "PROFILE=%~1"
if "!PROFILE!"=="" set "PROFILE=!LIBSCRIPT_ROOT_DIR!\profiles\illumos\minimal-server.json"
set "SYSROOT=%~2"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\illumos-sysroot"

for %%F in ("!PROFILE!") do set "PROFILE_NAME=%%~nF"
set "STAMP_DIR=!SYSROOT!\.libscript-stamps"
set "STAMP_FILE=!STAMP_DIR!\illumos-assemble-!PROFILE_NAME!.stamp"

if exist "!STAMP_FILE!" (
    echo [SKIP]     illumos profile ^(!PROFILE_NAME!^) already assembled at !SYSROOT!
    exit /b 0
)
if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"

set "ILLUMOS_VER=r151048"
set "ARCH=amd64"
set "POOL_NAME=rpool"
set "COMPRESSION=lz4"
set "HOSTNAME=illumos-node"
set "INIT_PROV=smf"
set "PKG_PROV=ips"
set "DISP_SRV=none"
set "DISP_COMP=none"
set "DESK_ENV=none"
set "DM_GREETER=none"
set "AUTOLOGIN="
set "AUDIO_SUB=none"

where jq >nul 2>&1
if not errorlevel 1 if exist "!PROFILE!" (
    for /f "usebackq delims=" %%V in (`jq -r ".illumos_version // \"r151048\"" "!PROFILE!"`) do set "ILLUMOS_VER=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".target.arch // \"amd64\"" "!PROFILE!"`) do set "ARCH=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".storage.pool_name // \"rpool\"" "!PROFILE!"`) do set "POOL_NAME=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".storage.compression // \"lz4\"" "!PROFILE!"`) do set "COMPRESSION=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".network.hostname // \"illumos-node\"" "!PROFILE!"`) do set "HOSTNAME=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".init_system.provider // \"smf\"" "!PROFILE!"`) do set "INIT_PROV=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".package_manager.provider // \"ips\"" "!PROFILE!"`) do set "PKG_PROV=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".audio.subsystem // \"none\"" "!PROFILE!"`) do set "AUDIO_SUB=%%V"
)

echo [ASSEMBLE] Synthesizing illumos ^(!ILLUMOS_VER!^) from profile !PROFILE_NAME!...
call "!SCRIPT_DIR!\base.cmd" "!SYSROOT!" "!ILLUMOS_VER!" "!ARCH!"
call "!SCRIPT_DIR!\zfs.cmd" "!SYSROOT!" "!POOL_NAME!" "!COMPRESSION!"
call "!SCRIPT_DIR!\config.cmd" "!SYSROOT!" "!HOSTNAME!" "UTC"
call "!SCRIPT_DIR!\pkg.cmd" "!SYSROOT!" "!PKG_PROV!"
call "!SCRIPT_DIR!\users.cmd" "!SYSROOT!" "vagrant" "vagrant" "1000" "yes"
call "!SCRIPT_DIR!\init.cmd" "!SYSROOT!" "!INIT_PROV!"
call "!SCRIPT_DIR!\display.cmd" "!SYSROOT!" "!DISP_SRV!" "!DISP_COMP!"
call "!SCRIPT_DIR!\desktop.cmd" "!SYSROOT!" "!DESK_ENV!" "vagrant"
call "!SCRIPT_DIR!\dm.cmd" "!SYSROOT!" "!DM_GREETER!" "!AUTOLOGIN!"
call "!SCRIPT_DIR!\audio.cmd" "!SYSROOT!" "!AUDIO_SUB!"

echo %DATE% %TIME%> "!STAMP_FILE!"
echo [OK]       illumos distribution assembly complete.
exit /b 0

:: ## show_help
:: Displays usage instructions for illumos distribution assembly on Windows.
:show_help
echo Usage: %~nx0 [profile_json_path] [target_sysroot]
exit /b 0
