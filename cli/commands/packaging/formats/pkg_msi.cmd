@echo off
:: # pkg_msi.cmd
::
:: ## Overview
:: Implements packaging logic for the 'msi' format on Windows.
:: 
:: ## Usage
:: Called by the packaging system to produce WiX (.wxs) installer scripts and compile MSIs.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\..\..\..\.."
)

call "%SCRIPT_DIR%\_common_installer_args.cmd" %*

set "wxs_file=%OUT_FILE%.wxs"
> "%wxs_file%" (
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
    echo   ^<Product Id="%PRODUCT_CODE%" Name="%APP_NAME%" Language="1033" Version="%APP_VERSION%" Manufacturer="%APP_PUBLISHER%" UpgradeCode="%UPGRADE_CODE%"^>
    echo     ^<Package InstallerVersion="200" Compressed="yes" InstallScope="%install_scope%" Description="%WELCOME_TEXT%" /^>
    echo     ^<Media Id="1" Cabinet="media1.cab" EmbedCab="yes" /^>
    if not "%ICON_PATH%"=="" echo     ^<Icon Id="AppIcon.ico" SourceFile="%ICON_PATH%"/^>
    echo     ^<Directory Id="TARGETDIR" Name="SourceDir"^>
    echo       ^<Directory Id="ProgramFilesFolder"^>
    echo         ^<Directory Id="INSTALLFOLDER" Name="%APP_NAME%" /^>
    echo       ^</Directory^>
    echo     ^</Directory^>
    echo     ^<Feature Id="ProductFeature" Title="%APP_NAME%" Level="1"^>
    echo     ^</Feature^>
    echo   ^</Product^>
    echo ^</Wix^>
)

echo Generated %wxs_file%
where candle >nul 2>&1
if %errorlevel% equ 0 (
    candle "%wxs_file%"
    if exist "%OUT_FILE%.wixobj" light "%OUT_FILE%.wixobj" -out "%OUT_FILE%.msi"
)
exit /b %errorlevel%
