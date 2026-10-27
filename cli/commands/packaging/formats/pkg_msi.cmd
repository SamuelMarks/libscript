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
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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
    set "LIBSCRIPT_ROOT_DIR=!SCRIPT_DIR!\..\..\..\.."
)

call "!SCRIPT_DIR!\_common_installer_args.cmd" %*

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
if errorlevel 1 where candle.exe >nul 2>&1
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\msi-rs\env.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\msi-rs\env.cmd" >nul 2>&1
    )
)
where candle >nul 2>&1
if errorlevel 1 where candle.exe >nul 2>&1
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install msi-rs v0.0.1 >nul 2>&1
        if exist "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\msi-rs\env.cmd" (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\msi-rs\env.cmd" >nul 2>&1
        )
    )
)
where candle >nul 2>&1
if errorlevel 1 where candle.exe >nul 2>&1
if %errorlevel% equ 0 (
    candle "%wxs_file%"
    if exist "%OUT_FILE%.wixobj" light "%OUT_FILE%.wixobj" -out "%OUT_FILE%.msi"
)
exit /b %errorlevel%
