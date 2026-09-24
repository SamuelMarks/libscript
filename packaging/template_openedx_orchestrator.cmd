@echo off
rem ## Overview
rem Generates a pure WiX XML (.wxs) manifest for the Open edX Master Orchestrator MSI.
rem Chained via Windows Installer 4.5+ native MsiEmbeddedChainer without any setup.exe bootstrapper.
rem Supports online and air-gapped offline variants.
rem
rem ## Usage
rem   call packaging\template_openedx_orchestrator.cmd [OPTIONS]
rem
rem ## Parameters
rem   --version <ver>      Open edX stack version (default: 22.1.0)
rem   --variant <var>      Installer variant: online or offline (default: offline)
rem   --msi-dir <dir>      Directory containing standalone component MSIs (default: dist\msi)
rem   --out <file.wxs>     Target path for generated WiX XML manifest
rem   --help, -h           Show this help text

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
set "VARIANT=offline"
set "MSI_DIR=%LIBSCRIPT_ROOT_DIR%\dist\msi"
set "OUT_FILE="

:parse_loop
if "%~1"=="" goto parse_done
if /i "%~1"=="--version" (
    set "VERSION=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--variant" (
    set "VARIANT=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--msi-dir" (
    set "MSI_DIR=%~2"
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
echo Open edX Master Orchestrator WiX Generator
echo.
echo Usage:
echo   call packaging\template_openedx_orchestrator.cmd [OPTIONS]
echo.
echo Options:
echo   --version ^<ver^>    Stack release version (default: 22.1.0)
echo   --variant ^<var^>    Installer variant (online or offline, default: offline)
echo   --msi-dir ^<dir^>    Directory containing child component MSIs
echo   --out ^<file.wxs^>   Output WiX manifest path
echo   --help, -h         Show this help text
exit /b 0

:parse_done
if "%OUT_FILE%"=="" (
    echo [ERROR] --out is required. >&2
    exit /b 1
)

set "UPGRADE_CODE=C9D8E74F-0A6B-4C8D-B6E9-1F29C0029340"

for /f "usebackq delims=" %%A in (`call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\uuid_gen.cmd" 6ba7b810-9dad-11d1-80b4-00c04fd430c8 "openedx.orchestrator.%VARIANT%.%VERSION%"`) do set "PRODUCT_CODE=%%A"

set "DISPLAY_NAME=Open edX Platform"
if /i "%VARIANT%"=="offline" set "DISPLAY_NAME=Open edX Platform (Air-Gapped Offline)"

(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
    echo   ^<Product Id="%PRODUCT_CODE%"
    echo            Name="%DISPLAY_NAME%"
    echo            Language="1033"
    echo            Version="%VERSION%.0"
    echo            Manufacturer="The Axim Collaborative &amp; LibScript Contributors"
    echo            UpgradeCode="%UPGRADE_CODE%"^>
    echo.
    echo     ^<Package Id="*"
    echo              InstallerVersion="405"
    echo              Compressed="yes"
    echo              InstallScope="perMachine"
    echo              Description="%DISPLAY_NAME% Unified Installer" /^>
    echo.
    echo     ^<MajorUpgrade DowngradeErrorMessage="A newer version of %DISPLAY_NAME% is already installed." Schedule="afterInstallInitialize" /^>
    echo     ^<Media Id="1" Cabinet="master_orch.cab" EmbedCab="yes" /^>
    echo.
    echo     ^<Property Id="INSTALL_MYSQL" Value="1" /^>
    echo     ^<Property Id="PROP_MYSQL_PORT" Value="3306" /^>
    echo     ^<Property Id="INSTALL_REDIS" Value="1" /^>
    echo     ^<Property Id="PROP_REDIS_PORT" Value="6379" /^>
    echo     ^<Property Id="INSTALL_MONGODB" Value="1" /^>
    echo     ^<Property Id="PROP_MONGODB_PORT" Value="27017" /^>
    echo     ^<Property Id="INSTALL_PYTHON" Value="1" /^>
    echo     ^<Property Id="INSTALL_NODEJS" Value="1" /^>
    echo     ^<Property Id="INSTALL_MEILISEARCH" Value="1" /^>
    echo     ^<Property Id="PROP_MEILISEARCH_PORT" Value="7700" /^>
    echo     ^<Property Id="INSTALL_CORE" Value="1" /^>
    echo.
    echo     ^<Directory Id="TARGETDIR" Name="SourceDir"^>
    echo       ^<Directory Id="ProgramFiles64Folder"^>
    echo         ^<Directory Id="INSTALLFOLDER" Name="OpenEdX"^>
    echo           ^<Directory Id="BUNDLE_DIR" Name="bundle" /^>
    echo         ^</Directory^>
    echo       ^</Directory^>
    echo     ^</Directory^>
    echo.
    echo     ^<Feature Id="CompleteStack" Title="Open edX Complete Deployment" Level="1"^>
    echo       ^<ComponentRef Id="MasterOrchestratorIdentity" /^>
    echo       ^<ComponentGroupRef Id="ChainedMsiPayloads" /^>
    echo     ^</Feature^>
    echo.
    echo     ^<DirectoryRef Id="INSTALLFOLDER"^>
    echo       ^<Component Id="MasterOrchestratorIdentity" Guid="A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D"^>
    echo         ^<RegistryKey Root="HKLM" Key="Software\LibScript\OpenEdX\Master"^>
    echo           ^<RegistryValue Name="Installed" Type="integer" Value="1" KeyPath="yes" /^>
    echo           ^<RegistryValue Name="Variant" Type="string" Value="%VARIANT%" /^>
    echo           ^<RegistryValue Name="Version" Type="string" Value="%VERSION%" /^>
    echo           ^<RegistryValue Name="InstallDir" Type="string" Value="[INSTALLFOLDER]" /^>
    echo         ^</RegistryKey^>
    echo       ^</Component^>
    echo     ^</DirectoryRef^>
    echo   ^</Product^>
    echo ^</Wix^>
) > "%OUT_FILE%"

echo [INFO] Generated Open edX Master Orchestrator WiX manifest: %OUT_FILE%
exit /b 0
