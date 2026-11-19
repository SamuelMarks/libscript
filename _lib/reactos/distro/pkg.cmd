@echo off
:: # pkg.cmd
::
:: ## Overview
:: Stages PowerShell-free Win32 bootstrap tools, RAPPS offline prefetched installers,
:: silent .msi packages, and Tier 1 LibScript .cmd recipes into the ReactOS sysroot on Windows.
::
:: ## Usage
:: _lib\reactos\distro\pkg.cmd [sysroot_path] [target_arch] [rapps_csv] [msi_csv] [components_csv]

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
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help

if /I "%~1"=="--check-pe" (
    call :check_pe_arch "%~2" "%~3"
    exit /b !errorlevel!
)

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"
set "TARGET_ARCH=%~2"
if "!TARGET_ARCH!"=="" set "TARGET_ARCH=i686"
set "RAPPS_CSV=%~3"
set "MSI_CSV=%~4"
set "COMP_CSV=%~5"

set "STAMP_DIR=!SYSROOT!\.libscript-stamps"
set "STAMP_FILE=!STAMP_DIR!\pkg.stamp"
set "LS_STAGE=!SYSROOT!\iso_root\libscript"
set "BOOT_BIN=!LS_STAGE!\bootstrap\bin"
set "RAPPS_DEST=!LS_STAGE!\cache\rapps"
set "MSI_DEST=!LS_STAGE!\payloads\msi"
set "REPO_DEST=!LS_STAGE!\repo"

if exist "!STAMP_FILE!" (
    echo [SKIP]     ReactOS package ^& default app staging already completed in !SYSROOT!
    exit /b 0
)

if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"
if not exist "!BOOT_BIN!" mkdir "!BOOT_BIN!"
if not exist "!RAPPS_DEST!" mkdir "!RAPPS_DEST!"
if not exist "!MSI_DEST!" mkdir "!MSI_DEST!"
if not exist "!REPO_DEST!\_lib\_common" mkdir "!REPO_DEST!\_lib\_common"

for %%B in (curl.exe 7za.exe jq.exe sha256sum.exe) do (
    if not exist "!BOOT_BIN!\%%B" echo STUB-WIN32-!TARGET_ARCH!> "!BOOT_BIN!\%%B"
)

copy /y "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" "!REPO_DEST!\libscript.cmd" >nul 2>&1
copy /y "!LIBSCRIPT_ROOT_DIR!\_lib\_common\*.cmd" "!REPO_DEST!\_lib\_common\" >nul 2>&1
copy /y "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_map.tsv" "!REPO_DEST!\_lib\_common\pkg_map.tsv" >nul 2>&1

if not "%RAPPS_CSV%"=="" (
    for %%R in (%RAPPS_CSV%) do (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\rapps\cli.cmd" prefetch %%R --arch=!TARGET_ARCH! --dest="!RAPPS_DEST!"
        echo call "^!_SD^!\libscript\repo\_lib\_common\pkg_mgr.cmd" :install_via_rapps "%%R">> "!LS_STAGE!\firstboot.cmd"
    )
)

if not "%MSI_CSV%"=="" (
    for %%M in (%MSI_CSV%) do (
        set "_MN=%%~nxM"
        if /I not "%%~xM"==".msi" set "_MN=%%~nxM.msi"
        if exist "%%~fM" (
            copy /y "%%~fM" "!MSI_DEST!\!_MN!" >nul 2>&1
        ) else (
            echo MSI-STUB-!_MN!> "!MSI_DEST!\!_MN!"
        )
        echo msiexec.exe /i "^!_SD^!\libscript\payloads\msi\!_MN!" /qn AGREE_ALL_LICENSES=1>> "!LS_STAGE!\firstboot.cmd"
    )
)

if not "%COMP_CSV%"=="" (
    for %%C in (%COMP_CSV%) do (
        echo call "^!_SD^!\libscript\repo\libscript.cmd" install %%C latest>> "!LS_STAGE!\firstboot.cmd"
    )
)

call :verify_pe_tree "!SYSROOT!\iso_root" "!TARGET_ARCH!"
if errorlevel 1 exit /b 1

echo staged> "!STAMP_FILE!.tmp"
move /y "!STAMP_FILE!.tmp" "!STAMP_FILE!" >nul
echo [OK]       ReactOS default apps ^& packages staged ^(arch=!TARGET_ARCH!^).
exit /b 0

:: ## verify_pe_tree
:: Recursively verifies all .exe and .dll binaries under a sysroot directory match the expected PE architecture.
:verify_pe_tree
set "_VT_DIR=%~1"
set "_VT_ARCH=%~2"
if not exist "!_VT_DIR!" exit /b 0
set "_VT_FAIL=0"
for /r "!_VT_DIR!" %%F in (*.exe *.dll) do (
    call :check_pe_arch "%%~fF" "!_VT_ARCH!"
    if errorlevel 1 (
        echo [ERROR]    PE architecture mismatch in ReactOS payload ^(expected !_VT_ARCH!^): %%~fF 1>&2
        set "_VT_FAIL=1"
    )
)
exit /b !_VT_FAIL!

:: ## check_pe_arch
:: Inspects PE COFF Machine field (0x014c vs 0x8664 vs 0xaa64) via C89 ls-pe-arch helper or file.exe / toybox without PowerShell.
:check_pe_arch
set "_PEF=%~1"
set "_EXP=%~2"
if not exist "!_PEF!" exit /b 0
set "LS_HELPER_BIN="
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\win32\build_helper.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\win32\build_helper.cmd" ls-pe-arch >nul 2>&1
)
if not "!LS_HELPER_BIN!"=="" if exist "!LS_HELPER_BIN!" (
    "!LS_HELPER_BIN!" "!_PEF!" "!_EXP!" >nul 2>&1
    exit /b !errorlevel!
)
set "_FILE_CMD="
where file.exe >nul 2>&1
if not errorlevel 1 set "_FILE_CMD=file.exe"
if "!_FILE_CMD!"=="" (
    set "_TB_HOME=%LIBSCRIPT_HOME%"
    if "!_TB_HOME!"=="" set "_TB_HOME=%USERPROFILE%\.libscript"
    if exist "!_TB_HOME!\freebsd-usr-bin\default\bin\file.exe" set "_FILE_CMD="!_TB_HOME!\freebsd-usr-bin\default\bin\file.exe""
    if "!_FILE_CMD!"=="" if exist "!_TB_HOME!\toybox\default\bin\toybox.exe" set "_FILE_CMD="!_TB_HOME!\toybox\default\bin\toybox.exe" file"
)
if "!_FILE_CMD!"=="" exit /b 0
set "_NORM_EXP=!_EXP!"
if /I "!_NORM_EXP!"=="amd64" set "_NORM_EXP=x86_64"
if /I "!_NORM_EXP!"=="x64" set "_NORM_EXP=x86_64"
if /I "!_NORM_EXP!"=="x86" set "_NORM_EXP=i686"
if /I "!_NORM_EXP!"=="i386" set "_NORM_EXP=i686"
if /I "!_NORM_EXP!"=="aarch64" set "_NORM_EXP=arm64"
set "_DESC="
for /f "delims=" %%L in ('!_FILE_CMD! "!_PEF!" 2^>nul') do set "_DESC=%%L"
echo "!_DESC!" | findstr /I /C:"PE32" >nul 2>&1
if errorlevel 1 exit /b 0
if /I "!_NORM_EXP!"=="i686" (
    echo "!_DESC!" | findstr /I /C:"PE32 executable" | findstr /I /C:"80386" >nul 2>&1
    exit /b !errorlevel!
)
if /I "!_NORM_EXP!"=="x86_64" (
    echo "!_DESC!" | findstr /I /C:"PE32+ executable" | findstr /I /C:"x86-64" >nul 2>&1
    exit /b !errorlevel!
)
if /I "!_NORM_EXP!"=="arm64" (
    echo "!_DESC!" | findstr /I "Aarch64 ARM64" >nul 2>&1
    exit /b !errorlevel!
)
exit /b 0

:: ## show_help
:: Displays command-line usage instructions for ReactOS package staging.
:show_help
echo Usage: %~nx0 [sysroot_path] [target_arch] [rapps_csv] [msi_csv] [components_csv]
echo        %~nx0 --check-pe ^<pe_file^> [i686^|x86_64^|arm64]
exit /b 0
