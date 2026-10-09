@echo off
:: # pkg_innosetup.cmd
::
:: ## Overview
:: Implements packaging logic for the 'innosetup' format on Windows.
:: 
:: ## Usage
:: Called by the packaging system to produce Inno Setup installer scripts (.iss).

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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\..\..\..\.."
)

call "%SCRIPT_DIR%\_common_installer_args.cmd" %*

set "iss_file=%OUT_FILE%.iss"
> "%iss_file%" (
    echo [Setup]
    echo AppName=%APP_NAME%
    echo AppVersion=%APP_VERSION%
    echo AppPublisher=%APP_PUBLISHER%
    if not "%APP_URL%"=="" echo AppPublisherURL=%APP_URL%
    echo DefaultDirName={autopf}\%APP_NAME%
    echo PrivilegesRequired=%inno_priv%
    echo OutputDir=.
    echo OutputBaseFilename=%OUT_FILE%
    if not "%UPGRADE_CODE%"=="PUT-GUID-HERE" echo AppId=%UPGRADE_CODE%
    if not "%ICON_PATH%"=="" echo SetupIconFile=%ICON_PATH%
    if not "%LICENSE_PATH%"=="" echo LicenseFile=%LICENSE_PATH%
    echo.
    echo [Files]
    echo Source: "%LIBSCRIPT_ROOT_DIR%\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
    echo.
    echo [Run]
    echo Filename: "{app}\libscript.cmd"; Parameters: "install-service"; Flags: runhidden
)

echo Generated %iss_file%
where iscc >nul 2>&1
if %errorlevel% equ 0 (
    echo Compiling %iss_file% with iscc...
    iscc "%iss_file%"
)
exit /b %errorlevel%
