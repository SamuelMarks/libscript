@echo off
:: # template_inno.cmd
::
:: ## Overview
:: Template file for Inno Setup installer generation on Windows.
:: 
:: ## Usage
:: This file is processed during the build phase and not executed directly.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%APP_NAME%"=="" set "APP_NAME=MyApp"
if "%APP_VERSION%"=="" set "APP_VERSION=1.0.0"
if "%APP_PUBLISHER%"=="" set "APP_PUBLISHER=MyCompany"
if "%OUT_FILE%"=="" set "OUT_FILE=installer"
if "%inno_priv%"=="" set "inno_priv=admin"

echo [Setup]
echo AppName=%APP_NAME%
echo AppVersion=%APP_VERSION%
echo AppPublisher=%APP_PUBLISHER%
if not "%APP_URL%"=="" (
    echo AppPublisherURL=%APP_URL%
    echo AppSupportURL=%APP_URL%
    echo AppUpdatesURL=%APP_URL%
)
echo DefaultDirName={autopf}\%APP_NAME%
echo PrivilegesRequired=%inno_priv%
echo OutputDir=.
echo OutputBaseFilename=%OUT_FILE%
if not "%UPGRADE_CODE%"=="" if not "%UPGRADE_CODE%"=="PUT-GUID-HERE" echo AppId=%UPGRADE_CODE%
if not "%ICON_PATH%"=="" echo SetupIconFile=%ICON_PATH%
if not "%BANNER_SIDE_PATH%"=="" (
    echo WizardImageFile=%BANNER_SIDE_PATH%
) else (
    if not "%IMAGE_PATH%"=="" echo WizardImageFile=%IMAGE_PATH%
)
if not "%BANNER_TOP_PATH%"=="" echo WizardSmallImageFile=%BANNER_TOP_PATH%
if not "%LICENSE_PATH%"=="" echo LicenseFile=%LICENSE_PATH%

echo.
echo [Files]
if defined LIBSCRIPT_ROOT_DIR (
    echo Source: "%LIBSCRIPT_ROOT_DIR%\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
) else (
    echo Source: "*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
)

echo.
echo [Run]
echo Filename: "{app}\libscript.cmd"; Parameters: "install-service"; Flags: runhidden
exit /b 0
