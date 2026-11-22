@echo off
:: # assemble.cmd
::
:: ## Overview
:: Master ReactOS modular distribution synthesizer on Windows.
:: Orchestrates base, filesystem, unattend, config, pkg, users, init, display, desktop, and audio stages.
::
:: ## Usage
:: synthesis\distro\reactos\assemble.cmd [profile_json_path] [target_sysroot]

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
if "!PROFILE!"=="" set "PROFILE=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\reactos\minimal-headless-i686.json"
set "SYSROOT=%~2"
if "!SYSROOT!"=="" set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"

if not exist "!PROFILE!" (
    echo [ERROR] ReactOS profile not found: !PROFILE! >&2
    exit /b 1
)

for %%F in ("!PROFILE!") do set "PROFILE_NAME=%%~nF"
set "STAMP_DIR=!SYSROOT!\.libscript-stamps"
set "STAMP_FILE=!STAMP_DIR!\reactos-assemble-!PROFILE_NAME!.stamp"

if exist "!STAMP_FILE!" (
    echo [SKIP]     ReactOS profile ^(!PROFILE_NAME!^) already assembled at !SYSROOT!
    exit /b 0
)
if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"

set "REACTOS_VER=0.4.16"
set "ARCH=i686"
set "VARIANT=bootcd"
set "FS_TYPE=fat32"
set "SERIAL_DBG=true"
set "COMP_NAME=REACTOS-NODE"
set "HOSTNAME_VAL=REACTOS-NODE"
set "RAPPS_CSV="
set "MSI_CSV="
set "COMP_CSV="
set "INIT_PROV=nt-scm"
set "SVC_EN=dhcp,eventlog,rpcss,umpnpmgr"
set "DISP_PROTO=win32-gdi"
set "DISP_DRV=vbemp"
set "DISP_RES=1024x768x32"
set "DESK_SHELL=explorer-classic"
set "DESK_THEME=classic"
set "AUTOLOGIN="
set "AUDIO_SUB=none"

where jq >nul 2>&1
if not errorlevel 1 (
    for /f "usebackq delims=" %%V in (`jq -r ".profile_name // empty" "!PROFILE!"`) do if not "%%V"=="" set "PROFILE_NAME=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".reactos_version // \"0.4.16\"" "!PROFILE!"`) do set "REACTOS_VER=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".target.arch // \"i686\"" "!PROFILE!"`) do set "ARCH=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".storage.filesystem // \"fat32\"" "!PROFILE!"`) do set "FS_TYPE=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".network.hostname // .unattend.computer_name // \"REACTOS-NODE\"" "!PROFILE!"`) do set "HOSTNAME_VAL=%%V"
    for /f "usebackq delims=" %%V in (`jq -r "(.rapps_packages // []) | join(\",\")" "!PROFILE!"`) do set "RAPPS_CSV=%%V"
    for /f "usebackq delims=" %%V in (`jq -r "(.msi_packages // []) | join(\",\")" "!PROFILE!"`) do set "MSI_CSV=%%V"
    for /f "usebackq delims=" %%V in (`jq -r "((.components // []) + (.packages // [])) | unique | join(\",\")" "!PROFILE!"`) do set "COMP_CSV=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".desktop.shell // \"explorer-classic\"" "!PROFILE!"`) do set "DESK_SHELL=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".desktop.theme // \"classic\"" "!PROFILE!"`) do set "DESK_THEME=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".desktop.autologin_user // empty" "!PROFILE!"`) do set "AUTOLOGIN=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".audio.subsystem // \"none\"" "!PROFILE!"`) do set "AUDIO_SUB=%%V"
)
set "STAMP_FILE=!STAMP_DIR!\reactos-assemble-!PROFILE_NAME!.stamp"
if exist "!STAMP_FILE!" (
    echo [SKIP]     ReactOS profile ^(!PROFILE_NAME!^) already assembled at !SYSROOT!
    exit /b 0
)

echo [ASSEMBLE] Synthesizing ReactOS !REACTOS_VER! ^(!ARCH!^) for profile !PROFILE_NAME!...
set "STACK=" & call "!SCRIPT_DIR!\base.cmd" --allow-stub "!SYSROOT!" "!REACTOS_VER!" "!ARCH!" "!VARIANT!"
set "STACK=" & call "!SCRIPT_DIR!\filesystem.cmd" "!SYSROOT!" "!FS_TYPE!" "!SERIAL_DBG!"
set "STACK=" & call "!SCRIPT_DIR!\unattend.cmd" "!SYSROOT!" "!HOSTNAME_VAL!" "" "00000409" "85" "!FS_TYPE!"
set "STACK=" & call "!SCRIPT_DIR!\config.cmd" "!SYSROOT!" "!HOSTNAME_VAL!" "true" "1.1.1.1,8.8.8.8"
set "STACK=" & call "!SCRIPT_DIR!\pkg.cmd" "!SYSROOT!" "!ARCH!" "!RAPPS_CSV!" "!MSI_CSV!" "!COMP_CSV!"
set "STACK=" & call "!SCRIPT_DIR!\users.cmd" "!SYSROOT!" "admin" "vagrant" "true" "!AUTOLOGIN!"
set "STACK=" & call "!SCRIPT_DIR!\init.cmd" "!SYSROOT!" "!INIT_PROV!" "!SVC_EN!"
set "STACK=" & call "!SCRIPT_DIR!\display.cmd" "!SYSROOT!" "!DISP_PROTO!" "!DISP_DRV!" "!DISP_RES!"
set "STACK=" & call "!SCRIPT_DIR!\desktop.cmd" "!SYSROOT!" "!DESK_SHELL!" "!DESK_THEME!"
set "STACK=" & call "!SCRIPT_DIR!\audio.cmd" "!SYSROOT!" "!AUDIO_SUB!"

echo echo done^> "^!_SD^!\libscript\.firstboot.done">> "!SYSROOT!\iso_root\libscript\firstboot.cmd"
echo echo [LIBSCRIPT-FIRSTBOOT-READY] ReactOS provisioning complete.>> "!SYSROOT!\iso_root\libscript\firstboot.cmd"
echo exit /b 0>> "!SYSROOT!\iso_root\libscript\firstboot.cmd"

echo assembled> "!STAMP_FILE!"
echo [OK]       ReactOS distribution assembly complete for !PROFILE_NAME!.
exit /b 0

:: ## show_help
:: Displays usage instructions for assemble.cmd.
:show_help
echo Usage: %~nx0 [profile_json_path] [target_sysroot]
exit /b 0
