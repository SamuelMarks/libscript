@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

:: # template_msi.cmd
::
:: ## Overview
:: Universal WiX XML (.wxs) manifest generator on Windows.
:: Synthesizes WiX manifests driven purely by packaging.json.
::
:: ## Usage
::   call packaging	emplate_msi.cmd <path_to_stack_or_packaging.json> --out <file.wxs> [OPTIONS]

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:found_root

set "TARGET_SPEC=%~1"
if "%TARGET_SPEC%"=="" (
    echo [ERROR] Target stack directory or packaging.json required >&2
    exit /b 1
)
shift

set "OUT_FILE="
set "VARIANT=online"
set "VERSION_OVERRIDE="

:arg_loop
if "%~1"=="" goto done_args
if /i "%~1"=="--out" ( set "OUT_FILE=%~2" & shift & shift & goto arg_loop )
if /i "%~1"=="--variant" ( set "VARIANT=%~2" & shift & shift & goto arg_loop )
if /i "%~1"=="--version" ( set "VERSION_OVERRIDE=%~2" & shift & shift & goto arg_loop )
shift
goto arg_loop

:done_args

if "%OUT_FILE%"=="" (
    echo [ERROR] --out parameter is required >&2
    exit /b 1
)

set "PKG_JSON=%TARGET_SPEC%"
if exist "%TARGET_SPEC%\packaging.json" set "PKG_JSON=%TARGET_SPEC%\packaging.json"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$pkgJson = '%PKG_JSON%';" ^
    "$outFile = '%OUT_FILE%';" ^
    "$variant = '%VARIANT%';" ^
    "$verOverride = '%VERSION_OVERRIDE%';" ^
    "$spec = Get-Content $pkgJson -Raw | ConvertFrom-Json;" ^
    "$name = if ($spec.name) { $spec.name } else { 'app' };" ^
    "$title = if ($spec.title) { $spec.title } else { $name };" ^
    "$ver = if ($verOverride) { $verOverride } elseif ($spec.version) { $spec.version } else { '1.0.0.0' };" ^
    "$pub = if ($spec.publisher) { $spec.publisher } else { 'LibScript Open Source Project' };" ^
    "$upgradeCode = if ($spec.upgrade_code) { $spec.upgrade_code } else { '{A0B1C2D3-E4F5-6A7B-8C9D-0E1F2A3B4C5D}' };" ^
    "$prodCode = [System.Guid]::NewGuid().ToString('B').ToUpper();" ^
    "$wxs = @'<?xml version="1.0" encoding="UTF-8"?>" ^
    "<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">" ^
    "  <Product Id="' + $prodCode + '" Name="' + $title + '" Language="1033" Version="' + $ver + '" Manufacturer="' + $pub + '" UpgradeCode="' + $upgradeCode + '">" ^
    "    <Package Id="*" InstallerVersion="405" Compressed="yes" InstallScope="perMachine" Description="' + $title + ' Installer" />" ^
    "    <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." Schedule="afterInstallInitialize" />" ^
    "    <Media Id="1" Cabinet="payload.cab" EmbedCab="yes" />" ^
    "    <Directory Id="TARGETDIR" Name="SourceDir">" ^
    "      <Directory Id="ProgramFiles64Folder">" ^
    "        <Directory Id="INSTALLFOLDER" Name="' + $name + '">" ^
    "          <Directory Id="BUNDLE_DIR" Name="bundle" />" ^
    "        </Directory>" ^
    "      </Directory>" ^
    "    </Directory>" ^
    "    <Feature Id="DefaultFeature" Title="' + $title + '" Level="1">" ^
    "      <ComponentRef Id="AppIdentityComponent" />" ^
    "    </Feature>" ^
    "    <DirectoryRef Id="INSTALLFOLDER">" ^
    "      <Component Id="AppIdentityComponent" Guid="*">" ^
    "        <RegistryKey Root="HKLM" Key="Software\LibScript' + $name + '">" ^
    "          <RegistryValue Name="Installed" Type="integer" Value="1" KeyPath="yes" />" ^
    "        </RegistryKey>" ^
    "      </Component>" ^
    "    </DirectoryRef>" ^
    "  </Product>" ^
    "</Wix>';" ^
    "[System.IO.File]::WriteAllText($outFile, $wxs);" ^
    "Write-Output ('[SUCCESS] Generated WiX XML: ' + $outFile);"

exit /b %ERRORLEVEL%
