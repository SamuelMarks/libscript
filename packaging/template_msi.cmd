@echo off
:: # template_msi.cmd
::
:: ## Overview
:: Template file for WiX MSI installer generation on Windows.
:: 
:: ## Usage
:: This file is processed during the build phase and not executed directly.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%APP_NAME%"=="" set "APP_NAME=MyApp"
if "%APP_VERSION%"=="" set "APP_VERSION=1.0.0"
if "%APP_PUBLISHER%"=="" set "APP_PUBLISHER=MyCompany"
if "%PRODUCT_CODE%"=="" set "PRODUCT_CODE=*"
if "%UPGRADE_CODE%"=="" set "UPGRADE_CODE=PUT-GUID-HERE"
if "%install_scope%"=="" set "install_scope=perMachine"

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
exit /b 0
