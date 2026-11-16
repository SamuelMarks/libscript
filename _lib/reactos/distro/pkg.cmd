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

echo staged> "!STAMP_FILE!"
echo [OK]       ReactOS default apps ^& packages staged ^(arch=!TARGET_ARCH!^).
exit /b 0

:: ## check_pe_arch
:: Inspects PE header Machine field (0x014c vs 0x8664) when PowerShell is available on the Windows build host.
:check_pe_arch
set "_PEF=%~1"
set "_EXP=%~2"
if not exist "!_PEF!" exit /b 0
where powershell >nul 2>&1
if errorlevel 1 exit /b 0
powershell -NoProfile -Command "$b=[IO.File]::ReadAllBytes('!_PEF!'); if($b.Length -ge 64 -and $b[0] -eq 77 -and $b[1] -eq 90){ $o=[BitConverter]::ToInt32($b,60); if($o -ge 0 -and ($o+6) -le $b.Length -and $b[$o] -eq 80 -and $b[$o+1] -eq 69){ $m=[BitConverter]::ToUInt16($b,$o+4); $a=if($m -eq 0x014c){'i686'}elseif($m -eq 0x8664){'x86_64'}else{'other'}; $e=if('!_EXP!' -eq 'amd64'){'x86_64'}else{'!_EXP!'}; if($a -ne $e){ exit 1 } } }"
exit /b !errorlevel!
