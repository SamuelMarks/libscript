@echo off
rem ## Overview
rem Generates a pure WiX XML (.wxs) manifest for a standalone LibScript component MSI.
rem Utilizes deterministic GUIDs and reference-counted services from packaging\guid_registry.json.
rem Supports 100% pure Windows Installer with zero external .exe dependencies.
rem
rem ## Usage
rem   call packaging	emplate_component_msi.cmd [OPTIONS]
rem
rem ## Parameters
rem   --component <name>    Component identifier (e.g. mysql, redis, mongodb, python, nodejs, meilisearch)
rem   --version <version>   Component release version (e.g. 8.0.39, 20.17.0)
rem   --out <file.wxs>      Output path for the generated WiX XML file
rem   --source-dir <dir>    Directory containing component payload binaries to package
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

set "COMPONENT="
set "VERSION=1.0.0"
set "VARIANT=offline"
set "OUT_FILE="
set "SOURCE_DIR="

:: ## parse_loop
:: Iterates over command line arguments and populates options.
:parse_loop
if "%~1"=="" goto parse_done
if /i "%~1"=="--component" (
    set "COMPONENT=%~2"
    shift
    shift
    goto parse_loop
)
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
if /i "%~1"=="--online" (
    set "VARIANT=online"
    shift
    goto parse_loop
)
if /i "%~1"=="--offline" (
    set "VARIANT=offline"
    shift
    goto parse_loop
)
if /i "%~1"=="--out" (
    set "OUT_FILE=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--source-dir" (
    set "SOURCE_DIR=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help
shift
goto parse_loop

:: ## show_help
:: Displays usage documentation and supported parameters.
:show_help
echo Standalone Component WiX Generator
echo.
echo Usage:
echo   call packaging\template_component_msi.cmd [OPTIONS]
echo.
echo Options:
echo   --component ^<name^>   Component name (mysql, redis, mongodb, python, nodejs, meilisearch)
echo   --version ^<ver^>      Version string (e.g. 8.0.39, default: 1.0.0)
echo   --variant ^<var^>      Installer variant: online or offline (default: offline)
echo   --online             Shorthand for --variant online
echo   --offline            Shorthand for --variant offline
echo   --out ^<file.wxs^>     Output WiX file path
echo   --source-dir ^<dir^>   Payload directory containing files to bundle
echo   --help, -h           Show this help text
exit /b 0

:: ## parse_done
:: Validates parameters, queries guid_registry.json, and generates WiX XML manifest.
:parse_done
if "%COMPONENT%"=="" (
    echo [ERROR] --component is required. >&2
    exit /b 1
)
if "%OUT_FILE%"=="" (
    echo [ERROR] --out is required. >&2
    exit /b 1
)

set "REGISTRY_JSON=%LIBSCRIPT_ROOT_DIR%\packaging\guid_registry.json"
if not exist "%REGISTRY_JSON%" (
    echo [ERROR] Registry file not found: %REGISTRY_JSON% >&2
    exit /b 1
)

:: Extract registry fields via PowerShell
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command ^
    "$reg = Get-Content -Raw '%REGISTRY_JSON%' | ConvertFrom-Json; $c = $reg.components.'%COMPONENT%'; if ($c) { $c.upgrade_code } else { '' }"`) do set "UPGRADE_CODE=%%A"

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command ^
    "$reg = Get-Content -Raw '%REGISTRY_JSON%' | ConvertFrom-Json; $c = $reg.components.'%COMPONENT%'; if ($c) { $c.component_guid } else { '' }"`) do set "COMPONENT_GUID=%%A"

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command ^
    "$reg = Get-Content -Raw '%REGISTRY_JSON%' | ConvertFrom-Json; $c = $reg.components.'%COMPONENT%'; if ($c -and $c.title) { $c.title.Replace('&amp;', '&').Replace('&', '&amp;') } else { '%COMPONENT%' }"`) do set "TITLE=%%A"

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command ^
    "$reg = Get-Content -Raw '%REGISTRY_JSON%' | ConvertFrom-Json; $c = $reg.components.'%COMPONENT%'; if ($c -and $c.service_name) { $c.service_name } else { '' }"`) do set "SERVICE_NAME=%%A"

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command ^
    "$reg = Get-Content -Raw '%REGISTRY_JSON%' | ConvertFrom-Json; $c = $reg.components.'%COMPONENT%'; if ($c -and $c.default_port) { $c.default_port } else { '' }"`) do set "DEFAULT_PORT=%%A"

set "SHARED_ATTR="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command ^
    "$reg = Get-Content -Raw '%REGISTRY_JSON%' | ConvertFrom-Json; $c = $reg.components.'%COMPONENT%'; if ($c -and $c.shared_dll_ref_count -ne $false) { 'yes' } else { 'no' }"`) do (
    if "%%A"=="yes" set "SHARED_ATTR=SharedDllRefCount="yes""
)

if "%UPGRADE_CODE%"=="" (
    echo [ERROR] Component %COMPONENT% not found in registry %REGISTRY_JSON% >&2
    exit /b 1
)

:: Generate deterministic ProductCode
for /f "usebackq delims=" %%A in (`call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\uuid_gen.cmd" 6ba7b810-9dad-11d1-80b4-00c04fd430c8 "libscript.%COMPONENT%.%VARIANT%.%VERSION%"`) do set "PRODUCT_CODE=%%A"

set "DISPLAY_TITLE=LibScript %TITLE%"
set "PKG_DESC=LibScript %TITLE% Standalone Installer"
if /i "%VARIANT%"=="online" (
    set "DISPLAY_TITLE=LibScript %TITLE% (Online)"
    set "PKG_DESC=LibScript %TITLE% Online Standalone Installer"
)
if /i "%VARIANT%"=="offline" (
    set "DISPLAY_TITLE=LibScript %TITLE% (Offline)"
    set "PKG_DESC=LibScript %TITLE% Offline Air-Gapped Standalone Installer"
)

set "DOWNLOAD_URL="
set "BUNDLE_JSON=%LIBSCRIPT_ROOT_DIR%\stacks\cms\openedx\offline_bundle.json"
if exist "%BUNDLE_JSON%" (
    if /i "%COMPONENT%"=="python" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).runtimes.python.url"`) do set "DOWNLOAD_URL=%%A"
    if /i "%COMPONENT%"=="nodejs" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).runtimes.nodejs.url"`) do set "DOWNLOAD_URL=%%A"
    if /i "%COMPONENT%"=="mysql" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.mysql.url"`) do set "DOWNLOAD_URL=%%A"
    if /i "%COMPONENT%"=="redis" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.redis.url"`) do set "DOWNLOAD_URL=%%A"
    if /i "%COMPONENT%"=="mongodb" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.mongodb.url"`) do set "DOWNLOAD_URL=%%A"
    if /i "%COMPONENT%"=="meilisearch" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.meilisearch.url"`) do set "DOWNLOAD_URL=%%A"
)

set "DIR_NAME=%COMPONENT%"
if /i "%COMPONENT%"=="mysql" set "DIR_NAME=MySQL"
if /i "%COMPONENT%"=="redis" set "DIR_NAME=Redis"
if /i "%COMPONENT%"=="mongodb" set "DIR_NAME=MongoDB"
if /i "%COMPONENT%"=="python" set "DIR_NAME=Python311"
if /i "%COMPONENT%"=="nodejs" set "DIR_NAME=Node20"
if /i "%COMPONENT%"=="meilisearch" set "DIR_NAME=Meilisearch"

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
    echo            Name="%DISPLAY_TITLE%"
    echo            Language="1033"
    echo            Version="%WIX_VERSION%"
    echo            Manufacturer="LibScript"
    echo            UpgradeCode="%UPGRADE_CODE%"^>
    echo.
    echo     ^<Package Id="*"
    echo              InstallerVersion="405"
    echo              Compressed="yes"
    echo              InstallScope="perMachine"
    echo              Description="%PKG_DESC%" /^>
    echo.
    echo     ^<MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed." Schedule="afterInstallInitialize" /^>
    echo     ^<Media Id="1" Cabinet="payload.cab" EmbedCab="yes" /^>
    echo.
    if not "%DEFAULT_PORT%"=="" echo     ^<Property Id="PORT" Value="%DEFAULT_PORT%" /^>
    if not "%SERVICE_NAME%"=="" echo     ^<Property Id="SERVICE_NAME" Value="%SERVICE_NAME%" /^>
    echo.
    echo     ^<Directory Id="TARGETDIR" Name="SourceDir"^>
    echo       ^<Directory Id="ProgramFiles64Folder"^>
    echo         ^<Directory Id="LibScriptRootFolder" Name="LibScript"^>
    echo           ^<Directory Id="INSTALLFOLDER" Name="%DIR_NAME%"^>
    echo             ^<Directory Id="BIN_DIR" Name="bin" /^>
    echo           ^</Directory^>
    echo         ^</Directory^>
    echo       ^</Directory^>
    echo       ^<Directory Id="CommonAppDataFolder"^>
    echo         ^<Directory Id="LibScriptDataRoot" Name="LibScript"^>
    echo           ^<Directory Id="COMPONENT_DATA_DIR" Name="%DIR_NAME%"^>
    echo             ^<Directory Id="DATA_DIR" Name="data" /^>
    echo           ^</Directory^>
    echo         ^</Directory^>
    echo       ^</Directory^>
    echo     ^</Directory^>
    echo.
    echo     ^<Feature Id="MainFeature" Title="%TITLE%" Level="1"^>
    echo       ^<ComponentRef Id="ComponentIdentityRecord" /^>
    if not "%SERVICE_NAME%"=="" echo       ^<ComponentRef Id="ServiceRegistrationComponent" /^>
    echo       ^<ComponentGroupRef Id="PayloadComponents" /^>
    echo     ^</Feature^>
    echo.
    echo     ^<DirectoryRef Id="INSTALLFOLDER"^>
    if defined SHARED_ATTR (
        echo       ^<Component Id="ComponentIdentityRecord" Guid="%COMPONENT_GUID%" %SHARED_ATTR%^>
    ) else (
        echo       ^<Component Id="ComponentIdentityRecord" Guid="%COMPONENT_GUID%"^>
    )
    echo         ^<RegistryKey Root="HKLM" Key="Software\LibScript\%COMPONENT%"^>
    echo           ^<RegistryValue Name="Installed" Type="integer" Value="1" KeyPath="yes" /^>
    echo           ^<RegistryValue Name="Variant" Type="string" Value="%VARIANT%" /^>
    echo           ^<RegistryValue Name="Version" Type="string" Value="%VERSION%" /^>
    echo           ^<RegistryValue Name="InstallDir" Type="string" Value="[INSTALLFOLDER]" /^>
    echo           ^<RegistryValue Name="Port" Type="string" Value="[PORT]" /^>
    echo         ^</RegistryKey^>
    echo       ^</Component^>
    echo     ^</DirectoryRef^>
) > "%OUT_FILE%"

if /i "%VARIANT%"=="online" if not "%DOWNLOAD_URL%"=="" (
    (
        echo     ^<CustomAction Id="CA_Download_%COMPONENT%"
        echo                   Directory="INSTALLFOLDER"
        echo                   ExeCommand="powershell.exe -NoProfile -ExecutionPolicy Bypass -Command &quot;if (-not (Test-Path '[INSTALLFOLDER]bin\*.exe')) { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $tmp = [IO.Path]::GetTempFileName() + '.zip'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile $tmp; Expand-Archive -Path $tmp -DestinationPath '[INSTALLFOLDER]' -Force; Remove-Item $tmp -Force }&quot;"
        echo                   Execute="deferred"
        echo                   Return="ignore"
        echo                   Impersonate="no" /^>
        echo     ^<InstallExecuteSequence^>
        echo       ^<Custom Action="CA_Download_%COMPONENT%" Before="InstallServices"^>NOT Installed^</Custom^>
        echo     ^</InstallExecuteSequence^>
    ) >> "%OUT_FILE%"
)

if not "%SERVICE_NAME%"=="" (
    for /f "usebackq delims=" %%A in (`call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\uuid_gen.cmd" 6ba7b810-9dad-11d1-80b4-00c04fd430c8 "service.%COMPONENT%"`) do set "SERVICE_GUID=%%A"
    (
        echo     ^<DirectoryRef Id="BIN_DIR"^>
        if defined SHARED_ATTR (
            echo       ^<Component Id="ServiceRegistrationComponent" Guid="!SERVICE_GUID!" %SHARED_ATTR%^>
        ) else (
            echo       ^<Component Id="ServiceRegistrationComponent" Guid="!SERVICE_GUID!"^>
        )
        echo         ^<RegistryValue Root="HKLM" Key="Software\LibScript\%COMPONENT%\Service" Name="ServiceName" Type="string" Value="[SERVICE_NAME]" KeyPath="yes" /^>
        echo         ^<ServiceInstall Id="Install_%COMPONENT%_Service"
        echo                         Name="%SERVICE_NAME%"
        echo                         DisplayName="LibScript %TITLE%"
        echo                         Type="ownProcess"
        echo                         Start="auto"
        echo                         ErrorControl="normal"
        echo                         Description="Managed service daemon for LibScript %TITLE%." /^>
        echo         ^<ServiceControl Id="Control_%COMPONENT%_Service"
        echo                         Name="%SERVICE_NAME%"
        echo                         Stop="both"
        echo                         Remove="uninstall"
        echo                         Wait="yes" /^>
        echo       ^</Component^>
        echo     ^</DirectoryRef^>
    ) >> "%OUT_FILE%"
)

(
    echo   ^</Product^>
    echo ^</Wix^>
) >> "%OUT_FILE%"

echo [INFO] Generated standalone WiX manifest: %OUT_FILE%
exit /b 0
