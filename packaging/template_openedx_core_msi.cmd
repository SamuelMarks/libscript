@echo off
rem ## Overview
rem Generates a pure WiX XML (.wxs) manifest for openedx-core.msi.
rem Packages the Open edX LMS/CMS codebase, scripts, configuration, and data folders.
rem Expects third-party dependencies (MySQL, Redis, etc.) as standalone reference-counted MSIs.
rem
rem ## Usage
rem   call packaging	emplate_openedx_core_msi.cmd [OPTIONS]
rem
rem ## Parameters
rem   --version <version>   Package version (default: 22.1.0)
rem   --out <file.wxs>      Output path for the generated WiX XML manifest
rem   --help, -h            Show this help text

setlocal enabledelayedexpansion

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1 && (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

set "VERSION=22.1.0"
set "OUT_FILE="

:parse_loop
if "%~1"=="" goto parse_done
if /i "%~1"=="--version" (
    set "VERSION=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--out" (
    set "OUT_FILE=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help
shift
goto parse_loop

:show_help
echo Open edX Core WiX Template Generator
echo.
echo Usage:
echo   call packaging	emplate_openedx_core_msi.cmd [OPTIONS]
echo.
echo Options:
echo   --version ^<ver^>    Package version (default: 22.1.0)
echo   --out ^<file.wxs^>   Output WiX manifest path
echo   --help, -h         Show this help text
exit /b 0

:parse_done
if "%OUT_FILE%"=="" (
    echo [ERROR] --out is required. >&2
    exit /b 1
)

set "UPGRADE_CODE=B8C8E64E-9B5A-4B7C-A5D8-0F18B9918239"

for /f "usebackq delims=" %%A in (`call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\uuid_gen.cmd" 6ba7b810-9dad-11d1-80b4-00c04fd430c8 "openedx.core.%VERSION%"`) do set "PRODUCT_CODE=%%A"

set "WIX_VERSION=%VERSION%"
for /f "tokens=1,2,3,4 delims=." %%a in ("%VERSION%") do (
    if not "%%d"=="" (
        set "WIX_VERSION=%%a.%%b.%%c.%%d"
    ) else if not "%%c"=="" (
        set "WIX_VERSION=%%a.%%b.%%c.0"
    ) else if not "%%b"=="" (
        set "WIX_VERSION=%%a.%%b.0.0"
    ) else (
        set "WIX_VERSION=%%a.0.0.0"
    )
)

(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
    echo   ^<Product Id="%PRODUCT_CODE%"
    echo            Name="Open edX Platform Core"
    echo            Language="1033"
    echo            Version="%WIX_VERSION%"
    echo            Manufacturer="The Axim Collaborative &amp; LibScript Contributors"
    echo            UpgradeCode="%UPGRADE_CODE%"^>
    echo.
    echo     ^<Package Id="*"
    echo              InstallerVersion="405"
    echo              Compressed="yes"
    echo              InstallScope="perMachine"
    echo              Description="Open edX Platform Core LMS and Studio Services" /^>
    echo.
    echo     ^<MajorUpgrade DowngradeErrorMessage="A newer version of Open edX Platform Core is already installed." Schedule="afterInstallInitialize" /^>
    echo     ^<Media Id="1" Cabinet="openedx_core.cab" EmbedCab="yes" /^>
    echo.
    echo     ^<Property Id="PROP_LMS_PORT" Value="8000" /^>
    echo     ^<Property Id="PROP_CMS_PORT" Value="8001" /^>
    echo     ^<Property Id="PROP_MYSQL_HOST" Value="127.0.0.1" /^>
    echo     ^<Property Id="PROP_MYSQL_PORT" Value="3306" /^>
    echo     ^<Property Id="PROP_REDIS_HOST" Value="127.0.0.1" /^>
    echo     ^<Property Id="PROP_REDIS_PORT" Value="6379" /^>
    echo     ^<Property Id="PROP_MONGODB_HOST" Value="127.0.0.1" /^>
    echo     ^<Property Id="PROP_MONGODB_PORT" Value="27017" /^>
    echo     ^<Property Id="PROP_MEILISEARCH_PORT" Value="7700" /^>
    echo.
    echo     ^<Directory Id="TARGETDIR" Name="SourceDir"^>
    echo       ^<Directory Id="ProgramFiles64Folder"^>
    echo         ^<Directory Id="INSTALLFOLDER" Name="OpenEdX"^>
    echo           ^<Directory Id="SCRIPTS_DIR" Name="scripts" /^>
    echo         ^</Directory^>
    echo       ^</Directory^>
    echo       ^<Directory Id="CommonAppDataFolder"^>
    echo         ^<Directory Id="OPENEDX_DATA_ROOT" Name="OpenEdX"^>
    echo           ^<Directory Id="DATA_DIR" Name="data" /^>
    echo           ^<Directory Id="LOGS_DIR" Name="logs" /^>
    echo           ^<Directory Id="BACKUPS_DIR" Name="backups" /^>
    echo         ^</Directory^>
    echo       ^</Directory^>
    echo       ^<Directory Id="ProgramMenuFolder"^>
    echo         ^<Directory Id="ApplicationProgramsFolder" Name="Open edX" /^>
    echo       ^</Directory^>
    echo     ^</Directory^>
    echo.
    echo     ^<Feature Id="OpenEdXCoreFeature" Title="Open edX Core" Level="1"^>
    echo       ^<ComponentRef Id="CoreIdentityRecord" /^>
    echo       ^<ComponentRef Id="CoursewareDataStore" /^>
    echo       ^<ComponentRef Id="CoursewareLogStore" /^>
    echo       ^<ComponentRef Id="CoursewareBackupStore" /^>
    echo       ^<ComponentRef Id="ApplicationShortcuts" /^>
    echo       ^<ComponentGroupRef Id="OpenEdXCorePayloadComponents" /^>
    echo     ^</Feature^>
    echo.
    echo     ^<DirectoryRef Id="INSTALLFOLDER"^>
    echo       ^<Component Id="CoreIdentityRecord" Guid="E2A89C15-99BD-4720-A0E8-A97A2E504F63"^>
    echo         ^<RegistryKey Root="HKLM" Key="Software\LibScript\OpenEdX"^>
    echo           ^<RegistryValue Name="Installed" Type="integer" Value="1" KeyPath="yes" /^>
    echo           ^<RegistryValue Name="Version" Type="string" Value="%VERSION%" /^>
    echo           ^<RegistryValue Name="InstallDir" Type="string" Value="[INSTALLFOLDER]" /^>
    echo           ^<RegistryValue Name="DataDir" Type="string" Value="[DATA_DIR]" /^>
    echo           ^<RegistryValue Name="LogsDir" Type="string" Value="[LOGS_DIR]" /^>
    echo         ^</RegistryKey^>
    echo       ^</Component^>
    echo     ^</DirectoryRef^>
    echo.
    echo     ^<DirectoryRef Id="DATA_DIR"^>
    echo       ^<Component Id="CoursewareDataStore" Guid="7F28A541-11C3-4E80-990A-46D91A883C12" Permanent="yes" NeverOverwrite="yes"^>
    echo         ^<CreateFolder /^>
    echo       ^</Component^>
    echo     ^</DirectoryRef^>
    echo.
    echo     ^<DirectoryRef Id="LOGS_DIR"^>
    echo       ^<Component Id="CoursewareLogStore" Guid="3E4A1521-884A-49A3-A65B-64771C5091E2" Permanent="yes" NeverOverwrite="yes"^>
    echo         ^<CreateFolder /^>
    echo       ^</Component^>
    echo     ^</DirectoryRef^>
    echo.
    echo     ^<DirectoryRef Id="BACKUPS_DIR"^>
    echo       ^<Component Id="CoursewareBackupStore" Guid="98127364-5A4B-4C3D-8E2F-1029384756BA" Permanent="yes" NeverOverwrite="yes"^>
    echo         ^<CreateFolder /^>
    echo       ^</Component^>
    echo     ^</DirectoryRef^>
    echo.
    echo     ^<DirectoryRef Id="ApplicationProgramsFolder"^>
    echo       ^<Component Id="ApplicationShortcuts" Guid="718293A4-B5C6-4D7E-8F90-123456789ABC"^>
    echo         ^<Shortcut Id="ApplicationStartMenuShortcutCLI"
    echo                   Name="Open edX Management Console"
    echo                   Description="Open edX Command-Line Operations"
    echo                   Target="[INSTALLFOLDER]cli.cmd"
    echo                   WorkingDirectory="INSTALLFOLDER" /^>
    echo         ^<Shortcut Id="ApplicationStartMenuShortcutHealth"
    echo                   Name="Open edX Health Diagnostics"
    echo                   Description="Full-stack health diagnostic probe"
    echo                   Target="[INSTALLFOLDER]healthcheck.cmd"
    echo                   WorkingDirectory="INSTALLFOLDER" /^>
    echo         ^<Shortcut Id="ApplicationStartMenuShortcutDbShell"
    echo                   Name="Open edX Database Console"
    echo                   Description="Interactive SQL and Datastore Console"
    echo                   Target="[INSTALLFOLDER]dbshell.cmd"
    echo                   WorkingDirectory="INSTALLFOLDER" /^>
    echo         ^<RemoveFolder Id="CleanUpShortCut" On="uninstall" /^>
    echo         ^<RegistryValue Root="HKCU" Key="Software\LibScript\OpenEdX\Shortcuts" Name="Installed" Type="integer" Value="1" KeyPath="yes" /^>
    echo       ^</Component^>
    echo     ^</DirectoryRef^>
    echo   ^</Product^>
    echo ^</Wix^>
) > "%OUT_FILE%"

echo [INFO] Generated Open edX Core WiX manifest: %OUT_FILE%
exit /b 0
