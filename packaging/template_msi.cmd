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
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## find_root
:: Finds the root directory of the libscript repository.
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:: ## find_root_loop
:: Iterates upward through the directory tree looking for libscript.cmd.
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:: ## found_root
:: Target label reached once the libscript root directory is located.
:found_root

if "%APP_NAME%"=="" set "APP_NAME=LibScript Deployment"
if "%APP_VERSION%"=="" set "APP_VERSION=1.0.0.0"
if "%APP_PUBLISHER%"=="" set "APP_PUBLISHER=LibScript"
if "%PRODUCT_CODE%"=="" set "PRODUCT_CODE=*"
if "%UPGRADE_CODE%"=="" set "UPGRADE_CODE=PUT-GUID-HERE"
if "%install_scope%"=="" set "install_scope=perMachine"
if "%WELCOME_TEXT%"=="" set "WELCOME_TEXT=Welcome to the LibScript Deployment Installer"
if "%OUT_FILE%"=="" set "OUT_FILE=LibScriptInstaller"

set "WXS_FILE=%OUT_FILE%.wxs"

> "%WXS_FILE%" (
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"^>
    echo   ^<Product Id="%PRODUCT_CODE%" Name="%APP_NAME%" Language="1033" Version="%APP_VERSION%" Manufacturer="%APP_PUBLISHER%" UpgradeCode="%UPGRADE_CODE%"^>
    echo     ^<Package InstallerVersion="200" Compressed="yes" InstallScope="%install_scope%" Description="%WELCOME_TEXT%" /^>
    echo     ^<Media Id="1" Cabinet="media1.cab" EmbedCab="yes" /^>
    if not "%ICON_PATH%"=="" (
        echo     ^<Icon Id="AppIcon.ico" SourceFile="%ICON_PATH%"/^>
        echo     ^<Property Id="ARPPRODUCTICON" Value="AppIcon.ico" /^>
    )
    if not "%APP_URL%"=="" echo     ^<Property Id="ARPURLINFOABOUT" Value="%APP_URL%" /^>
    if not "%BANNER_TOP_PATH%"=="" echo     ^<WixVariable Id="WixUIBannerBmp" Value="%BANNER_TOP_PATH%" /^>
    if not "%BANNER_SIDE_PATH%"=="" echo     ^<WixVariable Id="WixUIDialogBmp" Value="%BANNER_SIDE_PATH%" /^>
    if not "%LICENSE_PATH%"=="" echo     ^<WixVariable Id="WixUILicenseRtf" Value="%LICENSE_PATH%" /^>

    echo     ^<Directory Id="TARGETDIR" Name="SourceDir"^>
    echo       ^<Directory Id="ProgramFilesFolder"^>
    echo         ^<Directory Id="INSTALLFOLDER" Name="%APP_NAME%" /^>
    echo       ^</Directory^>
    echo     ^</Directory^>

    echo     ^<UI Id="CustomUI"^>
    echo       ^<Property Id="DefaultUIFont" Value="WixUI_Font_Normal" /^>
    if not "%LICENSE_PATH%"=="" (
        echo       ^<Dialog Id="Dlg_License" Width="370" Height="270" Title="License Agreement"^>
        echo         ^<Control Id="Title" Type="Text" X="15" Y="6" Width="340" Height="15" Transparent="yes" NoPrefix="yes" Text="Please read and accept the license terms:" /^>
        echo         ^<Control Id="AgreementText" Type="ScrollableText" X="20" Y="25" Width="330" Height="180" Sunken="yes" TabSkip="no"^>
        echo           ^<Text SourceFile="%LICENSE_PATH%" /^>
        echo         ^</Control^>
        echo         ^<Control Id="LicenseAcceptedCheckBox" Type="CheckBox" X="20" Y="212" Width="330" Height="18" Property="LICENSE_ACCEPTED" CheckBoxValue="1" Text="I accept the terms in the License Agreement" /^>
        echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
        echo           ^<Publish Event="EndDialog" Value="Return"^>^<![CDATA[LICENSE_ACCEPTED="1"]]^>^</Publish^>
        echo         ^</Control^>
        echo       ^</Dialog^>
        echo       ^<Property Id="LICENSE_ACCEPTED" Value="0" Secure="yes" /^>
    )

    echo       ^<Dialog Id="Dlg_Features" Width="370" Height="270" Title="Select Components"^>
    echo         ^<Control Id="Lbl_Select" Type="Text" X="20" Y="10" Width="330" Height="15" Text="Select the components you want to install:" /^>
    echo         ^<Control Id="Next" Type="PushButton" X="236" Y="243" Width="56" Height="17" Default="yes" Text="Next"^>
    echo           ^<Publish Event="EndDialog" Value="Return"^>1^</Publish^>
    echo         ^</Control^>
    echo       ^</Dialog^>

    echo       ^<InstallUISequence^>
    if not "%LICENSE_PATH%"=="" (
        echo         ^<Show Dialog="Dlg_License" After="CostFinalize"^>NOT Installed^</Show^>
        echo         ^<Show Dialog="Dlg_Features" After="Dlg_License"^>NOT Installed^</Show^>
    ) else (
        echo         ^<Show Dialog="Dlg_Features" After="CostFinalize"^>NOT Installed^</Show^>
    )
    echo       ^</InstallUISequence^>
    echo     ^</UI^>

    echo     ^<Feature Id="ProductFeature" Title="%APP_NAME%" Level="1"^>
    echo       ^<ComponentGroupRef Id="ProductComponents" /^>
    echo     ^</Feature^>

    echo     ^<InstallExecuteSequence^>
    echo     ^</InstallExecuteSequence^>
    echo   ^</Product^>

    echo   ^<Fragment^>
    echo     ^<ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER"^>
    echo     ^</ComponentGroup^>
    echo   ^</Fragment^>
    echo ^</Wix^>
)

where wix.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    wix.exe build -ext WixToolset.UI.wixext -o "%OUT_FILE%.msi" "%WXS_FILE%"
    exit /b %ERRORLEVEL%
)

where candle.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    candle.exe "%WXS_FILE%"
    light.exe -ext WixUIExtension -out "%OUT_FILE%.msi" "%OUT_FILE%.wixobj"
    exit /b %ERRORLEVEL%
)

exit /b 0
