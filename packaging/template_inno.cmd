@echo off
:: # template_inno.cmd
::
:: ## Overview
:: Template file for Inno Setup installer generation on Windows.
:: Supports tasks, icons, post-install service setup, and uninstallation hooks.
:: 
:: ## Usage
:: This file is processed during the build phase and not executed directly.

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

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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
echo [Tasks]
echo Name: "workers"; Description: "Launch Celery background workers and beat scheduler"; Flags: unchecked
echo Name: "demo_content"; Description: "Import edX demo course and content libraries"; Flags: unchecked
echo Name: "mfes"; Description: "Build and deploy Micro-Frontends (Learning, Authn, Account)"; Flags: unchecked

echo.
echo [Files]
if defined LIBSCRIPT_ROOT_DIR (
    echo Source: "%LIBSCRIPT_ROOT_DIR%\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
) else (
    echo Source: "*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
)

echo.
echo [Icons]
echo Name: "{autoprograms}\%APP_NAME%\%APP_NAME% Management Console"; Filename: "{app}\stacks\cms\openedx\cli.cmd"
echo Name: "{autoprograms}\%APP_NAME%\%APP_NAME% Healthcheck"; Filename: "{app}\stacks\cms\openedx\healthcheck.cmd"
echo Name: "{autoprograms}\%APP_NAME%\%APP_NAME% Database Console"; Filename: "{app}\stacks\cms\openedx\dbshell.cmd"; Parameters: "mysql"
echo Name: "{autoprograms}\%APP_NAME%\%APP_NAME% Backup and Restore"; Filename: "{app}\stacks\cms\openedx\backup.cmd"

echo.
echo [Run]
echo Filename: "{app}\libscript.cmd"; Parameters: "install-service"; Flags: runhidden
echo Filename: "cmd.exe"; Parameters: "/c ""{app}\stacks\cms\openedx\workers.cmd"" start"; Tasks: workers; Flags: runhidden
echo Filename: "cmd.exe"; Parameters: "/c ""{app}\stacks\cms\openedx\import_demo.cmd"" course"; Tasks: demo_content; Flags: runhidden
echo Filename: "cmd.exe"; Parameters: "/c ""{app}\stacks\cms\openedx\mfe.cmd"" build all && ""{app}\stacks\cms\openedx\mfe.cmd"" deploy all"; Tasks: mfes; Flags: runhidden
echo Filename: "cmd.exe"; Parameters: "/c ""{app}\stacks\cms\openedx\healthcheck.cmd"""; Flags: runhidden

echo.
echo [UninstallRun]
echo Filename: "cmd.exe"; Parameters: "/c ""{app}\stacks\cms\openedx\workers.cmd"" stop"; Flags: runhidden
exit /b 0
